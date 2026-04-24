# Rapport projet Mr-News — Espace agence, espace admin, et travail à venir

Ce document sert à **l’équipe** (en particulier la personne chargée de l’**administration**) pour comprendre **ce qui existe**, **ce qui a été fait côté agence / base de données**, **le rôle des fichiers admin** visibles dans Git, et **le travail prévu** pour un vrai parcours « Espace administration ».

---

## 1. Deux espaces différents dans l’application

| Espace              | Public visé                                                                       | Idée                                                                                                                                                                            |
| ------------------- | --------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Agence (médias)** | Rédacteurs / structures qui publient des articles                                 | Inscription, connexion, tableau de bord, publication, modification, profil. Les données passent par la table **`agencies`** et **`articles`**.                                  |
| **Administration**  | Personnes qui valident les agences, gèrent les signalements, les catégories, etc. | Écrans sous les routes **`/admin`** … Le **rôle** est porté par le **compte Auth** (`user_metadata.role = admin`), **pas** par une colonne `role` dans la table **`agencies`**. |

La table **`agencies`** décrit le **profil média** (nom, email, `status` pending/approved/rejected, etc.). Elle **ne contient pas** un champ « role admin ».

---

## 2. Ce qui a été mis en place côté agence et Supabase (résumé A → Z)

_(Synthèse des évolutions déjà intégrées au projet pour que l’espace agence et la base restent cohérents.)_

- **RLS (sécurité lignes à lignes) sur `articles`**
  - Publication / mise à jour / suppression alignées sur la **possession** de l’agence via **`auth.uid()`** et la table **`agencies`**, avec des correctifs pour éviter les « succès » affichés alors qu’aucune ligne n’était modifiée.
  - Fichiers de référence SQL : `lib/supabase/rls_policies.sql`, migrations `supabase/migrations/003_fix_articles_update_delete_rls.sql` (et contexte `001` / `002` pour le schéma et l’insert).

- **Application Flutter (agence)**
  - Dépôt **`agency_repository`** : CRUD articles, upload couverture Storage, vérifications après `update`/`delete`.
  - Formulaires / écrans : publication, édition, carte agence (ex. libellé catégorie selon la **langue de l’article**), dialogue de suppression, upload image depuis le **téléphone** à l’édition, etc.

- **Espace admin dans le code**
  - **Données** : `AdminRepository` branché sur Supabase (stats, agences par statut, signalements, approbation / rejet / suspension).
  - **Écrans** : pour l’instant des **pages statiques** (« à compléter »), sans navigation complète depuis le feed ni **connexion dédiée admin**.

---

## 3. Fichiers « admin — rôle de chacun

| Fichier                                                | Rôle                                                                                                                                                                                                                        |
| ------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`lib/features/admin/data/admin_repository.dart`**    | Couche **données** admin : appels Supabase (`agencies`, `articles`, `reports`, `categories`), stats globales, listes, **`approveAgency` / `rejectAgency` / `suspendAgency`**, gestion d’erreurs `AdminRepositoryException`. |
| **`lib/features/admin/ui/stats_dashboard.dart`**       | Écran **tableau de bord admin** (`AdminDashboardScreen`) — route **`/admin`**. Contenu encore **placeholder** (texte « à compléter »).                                                                                      |
| **`lib/features/admin/ui/agency_validation.dart`**     | Écran **validation des agences** — route **`/admin/validation`**. Placeholder.                                                                                                                                              |
| **`lib/features/admin/ui/reports_management.dart`**    | Écran **signalements** — route **`/admin/reports`**. Placeholder.                                                                                                                                                           |
| **`lib/features/admin/ui/categories_management.dart`** | Écran **gestion des catégories** — route **`/admin/categories`**. Placeholder.                                                                                                                                              |
| **`lib/features/admin/ui/agencies_list.dart`**         | Écran **liste des agences** — route **`/admin/agencies`**. Placeholder.                                                                                                                                                     |

**Fichier lié (hors dossier `admin/`, mais utile pour l’admin)**

| Fichier                                               | Rôle                                                                                                                                                                                                        |
| ----------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`lib/features/feed/providers/feed_providers.dart`** | Déclare **`adminRepositoryProvider`**, **`adminStatsProvider`**, **`pendingAgenciesProvider`**, **`pendingReportsProvider`** pour brancher l’UI admin sur le repository quand les écrans seront développés. |

---

## 4. Comment le rôle « admin » fonctionne (Supabase + app)

- Le **rôle** `admin` se met dans les **métadonnées utilisateur** Auth (JSON **`raw_user_meta_data`** / équivalent **User metadata** dans le dashboard), avec une clé du type **`role`** = **`admin`**.
- Ce n’est **pas** une colonne dans le tableau liste des utilisateurs ; ce n’est **pas** non plus dans la table **`agencies`**.
- Le **routeur** (`lib/app/router.dart`) vérifie : pour toute URL qui commence par **`/admin`**, l’utilisateur doit être **connecté** et avoir **`userMetadata['role'] == 'admin'`**, sinon redirection vers le **feed**.

**Limite actuelle de la connexion**

- L’écran **`AgencyLoginScreen`** utilise **`AgencyAuthService.login`**, qui exige une ligne dans **`agencies`** pour l’`auth_user_id`. Un compte **admin seul**, sans ligne agence, **ne peut pas** passer par ce formulaire tel qu’il est écrit aujourd’hui.
- Après une connexion réussie par ce formulaire, l’app envoie vers le **tableau de bord agence**, **pas** automatiquement vers **`/admin`**.
- Il n’y a **pas** de bouton « Espace administration » sur le feed pour ouvrir l’admin sur mobile.

---

## 5. Routes admin déjà définies dans l’app (`AppRoutes` / `go_router`)

À utiliser pour la navigation (boutons, drawer, `context.go`, etc.) une fois le parcours admin en place :

| Chemin                  | Constante `AppRoutes` | Écran (widget)               |
| ----------------------- | --------------------- | ---------------------------- |
| **`/admin`**            | `adminDashboard`      | `AdminDashboardScreen`       |
| **`/admin/validation`** | `adminValidation`     | `AgencyValidationScreen`     |
| **`/admin/reports`**    | `adminReports`        | `ReportsManagementScreen`    |
| **`/admin/categories`** | `adminCategories`     | `CategoriesManagementScreen` |
| **`/admin/agencies`**   | `adminAgencies`       | `AgenciesListScreen`         |

Fichier de référence : **`lib/app/router.dart`**.

**Note redirect actuel** : si l’utilisateur n’est pas connecté et tente une route **`/admin`**, le redirect envoie vers **`AppRoutes.agencyLogin`** (`/agency/login`). Pour un parcours propre, il faudra probablement une route du type **`/admin/login`** et adapter ce redirect.

---

## 6. Travail demandé pour la personne « espace admin » (spec produit / technique)

Objectif : **séparer clairement** l’expérience **média (agence)** et **administration**, comme il existe déjà une idée de bouton **« Espace agence »** sur le feed.

### 6.1 Entrée depuis le fil d’actualités

- Ajouter un bouton **`Espace administration`** (même idée que **« Espace agence »**), visible selon les règles produit (par ex. toujours pour test, ou seulement si besoin).
- Ce bouton ouvre soit **directement** l’écran de **connexion admin**, soit une **petite page d’accueil admin** avec un lien « Se connecter ».

### 6.2 Formulaire de connexion **réservé à l’administration**

- Créer un écran dédié (ex. **`AdminLoginScreen`**) avec email + mot de passe.
- Utiliser **`signInWithPassword`** (Supabase Auth).
- **Ne pas** exiger une ligne **`agencies`** pour un utilisateur qui est uniquement admin (logique différente de `AgencyAuthService.login`).
- Après succès : lire **`user.userMetadata?['role']`** ; si ce n’est **pas** `admin`, afficher un message du type « Accès réservé aux administrateurs » et **déconnecter** ou empêcher l’entrée.
- Si le rôle est **`admin`** : **rediriger immédiatement** vers **`/admin`** (`context.go(AppRoutes.adminDashboard)` ou équivalent).

### 6.3 Depuis `/admin` : navigation vers les autres écrans

- Sur le **dashboard admin** (et/ou un **drawer** / menu latéral admin), ajouter des **boutons ou liens** vers :
  - `/admin/validation`
  - `/admin/reports`
  - `/admin/categories`
  - `/admin/agencies`
- Remplacer progressivement les textes « à compléter » par les **vraies listes** et actions, en s’appuyant sur **`AdminRepository`** et les providers dans **`feed_providers.dart`** (`adminStatsProvider`, `pendingAgenciesProvider`, `pendingReportsProvider`, etc.).

### 6.4 Routeur (`router.dart`)

- Ajouter une route **`/admin/login`** (ou nom équivalent) en **route publique** si besoin.
- Mettre à jour le **`redirect`** : pour les URLs **`/admin`**, si non authentifié → envoyer vers **`/admin/login`** plutôt que vers **`/agency/login`**.
- Garder la règle : accès aux routes **`/admin`** (sauf login) uniquement si **`role == 'admin'`**.

### 6.5 Comptes de test

- Créer un utilisateur Auth dans Supabase.
- Renseigner **`role`: `admin`** dans **`raw_user_meta_data`**.
- **Option développement** : si on continue temporairement à tester via l’ancien flux, une même personne peut avoir **à la fois** `role: admin` **et** une ligne **`agencies`** ; ce n’est qu’un **contournement**, pas le modèle cible.

---

## 7. Résumé pour l’équipe

| Qui                                      | Quoi                                                                                                                                                                                                        |
| ---------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Auteur du rapport (côté agence / BD)** | RLS articles, repository agence, formulaires, corrections UX (publication, édition, suppression, images, etc.).                                                                                             |
| **Fichiers admin dans Git**              | Surtout **`admin_repository`** (logique réelle) + **écrans UI placeholders** + providers dans **`feed_providers`**.                                                                                         |
| **Développeur admin à venir**            | Bouton **« Espace administration »**, **login admin dédié**, redirection **`/admin`**, menu vers **toutes les routes** listées en section 5, puis **implémentation UI** branchée sur **`AdminRepository`**. |

---

_Document généré pour le dépôt **mr-news** — à faire évoluer avec la branche Git et les décisions produit._
