# README --- CompletFileAdminAgence (Mr-News)

## 🎯 Objective

This document defines how to CONTINUE the Admin part of the Mr-News
project without rebuilding anything from scratch.

------------------------------------------------------------------------

## 📚 Required Reading Order

1.  README_agency.md\
2.  admin_agency.md\
3.  This file

------------------------------------------------------------------------

## ⚠️ Important Rules

-   Do NOT start from scratch
-   Do NOT change database structure
-   Do NOT modify Supabase logic
-   Do NOT change UI theme or colors
-   Only extend existing code

------------------------------------------------------------------------

## 🧩 Tasks

### 1. Admin Login

Create: AdminLoginScreen

-   Email + Password
-   Use signInWithPassword()
-   Check: user.userMetadata\['role'\] == 'admin'

If not admin → deny access\
If admin → redirect to /admin

------------------------------------------------------------------------

### 2. Navigation

From /admin:

-   /admin/validation
-   /admin/reports
-   /admin/categories
-   /admin/agencies

------------------------------------------------------------------------

### 3. Connect to Backend

Use:

-   AdminRepository
-   feed_providers.dart

DO NOT create new backend

------------------------------------------------------------------------

### 4. Replace Placeholder UI

Convert all "to be completed" pages into:

-   Real lists
-   Actions (approve / reject / suspend)

------------------------------------------------------------------------

### 5. Router

Add: - /admin/login

Update redirect:

-   Not logged in → /admin/login
-   Not admin → block

------------------------------------------------------------------------

### 6. Entry Button

Add button in Feed: "Espace Administration"

------------------------------------------------------------------------

## 🎨 UI Rules

-   Keep same design
-   Keep same colors
-   Clean UI only

------------------------------------------------------------------------

## ✅ Final Goal

-   Working Admin login
-   Functional dashboard
-   Connected UI
-   No breaking changes

------------------------------------------------------------------------

## 🚀 Summary

Continue the project. Do NOT rebuild.
