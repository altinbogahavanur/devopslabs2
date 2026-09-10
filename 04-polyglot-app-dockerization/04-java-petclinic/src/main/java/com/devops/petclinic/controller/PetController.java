package com.devops.petclinic.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.HashMap;
import java.util.Map;

@RestController
public class PetController {

    @GetMapping("/")
    public Map<String, Object> getHome() {
        Map<String, Object> res = new HashMap<>();
        res.put("message", "Spring Boot PetClinic Demo Aktif!");
        res.put("service", "petclinic-backend");
        res.put("runtime", System.getProperty("java.version"));
        res.put("max_memory_mb", Runtime.getRuntime().maxMemory() / (1024 * 1024));
        return res;
    }

    @GetMapping("/api/pets")
    public Object[] getPets() {
        return new Object[]{
            Map.of("id", 1, "name", "Leo", "type", "Kedi", "owner", "George Franklin"),
            Map.of("id", 2, "name", "Basil", "type", "Hamster", "owner", "Betty Davis"),
            Map.of("id", 3, "name", "Rosy", "type", "Kopek", "owner", "Eduardo Rodriquez")
        };
    }
}
