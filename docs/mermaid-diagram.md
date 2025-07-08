---
config:
  layout: dagre
---
flowchart TD
 subgraph subGraph0["User's Browser"]
        WebApp["Web Application<br><em>Runs in Browser</em>"]
  end
 subgraph subGraphRP["Reverse Proxy"]
        ReverseProxy["Reverse Proxy<br><em>(Caddy)</em>"]
  end
 subgraph subGraph1["Pages and REST Tier"]
        Static["HTML CSS<br>js images"]
        REST["REST API Gateway<br><em>(Routes, Middleware, Logic)</em>"]
  end
 subgraph subGraph2["Services"]
        Auth["Auth Service"]
        Models["Models Service"]
  end
 subgraph subGraph4["Database Tier"]
        Redis["Redis/Valkey"]
  end
 subgraph subGraph5["External Services"]
        Firebase["Firebase Auth"]
  end
    WebApp --> ReverseProxy
    ReverseProxy --> Static & REST
    REST -- <br> --> Auth & Models
    Auth -- <br> --> Firebase
    Auth -- <br> --> Redis
    Models -- <br> --> Redis
     WebApp:::client
     ReverseProxy:::client
     Static:::client
     REST:::client
     Auth:::service_tier
     Models:::service_tier
     Redis:::db
     Firebase:::external
    classDef client fill:#e6f3ff,stroke:#0066cc,stroke-width:2px
    classDef web_tier fill:#f0fff0,stroke:#2e8b57,stroke-width:2px
    classDef service_tier fill:#fff0f5,stroke:#c71585,stroke-width:2px
    classDef data_access fill:#fff8dc,stroke:#daa520,stroke-width:2px
    classDef db fill:#ffebcd,stroke:#a0522d,stroke-width:2px
    classDef external fill:#f5f5f5,stroke:#666,stroke-width:2px

