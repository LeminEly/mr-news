# Spring Boot Backend Implementation for Agency Management

To fix the 501 error and implement the required endpoints, you need to add or update the following code in your Spring Boot project.

## 1. Agency Entity
Ensure your `Agency` entity has the `status` field.

```java
package com.mrnews.api.model;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "agencies")
@Data
public class Agency {
    @Id
    private String id;
    
    private String name;
    private String email;
    
    @Column(name = "status")
    private String status; // Allowed values: PENDING, ACCEPTED, REJECTED
    
    // ... other fields (logo_url, website_url, etc.)
}
```

## 2. Agency Repository
```java
package com.mrnews.api.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import com.mrnews.api.model.Agency;

public interface AgencyRepository extends JpaRepository<Agency, String> {
}
```

## 3. Admin Agency Controller
This controller implements the `approve` and `reject` endpoints.

```java
package com.mrnews.api.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.mrnews.api.model.Agency;
import com.mrnews.api.repository.AgencyRepository;

@RestController
@RequestMapping("/api/admin/agencies")
@CrossOrigin(origins = "*")
public class AdminAgencyController {

    @Autowired
    private AgencyRepository agencyRepository;

    @PutMapping("/{id}/approve")
    public ResponseEntity<?> approveAgency(@PathVariable String id) {
        return agencyRepository.findById(id)
            .map(agency -> {
                agency.setStatus("ACCEPTED");
                agencyRepository.save(agency);
                return ResponseEntity.ok("Agency approved successfully");
            })
            .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}/reject")
    public ResponseEntity<?> rejectAgency(@PathVariable String id) {
        return agencyRepository.findById(id)
            .map(agency -> {
                agency.setStatus("REJECTED");
                agencyRepository.save(agency);
                return ResponseEntity.ok("Agency rejected successfully");
            })
            .orElse(ResponseEntity.notFound().build());
    }
}
```

## 4. Database Fix (SQL)
Run this SQL to ensure the table structure is correct.

```sql
ALTER TABLE agencies MODIFY COLUMN status VARCHAR(20) DEFAULT 'PENDING';
-- Ensure existing rows have a valid status
UPDATE agencies SET status = 'PENDING' WHERE status IS NULL;
```
