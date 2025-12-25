# ELT proces datasetu Global Public Companies Traffic Growth

Tento repozitár predstavuje implementáciu ELT procesu v Snowflake a vytvorenie dátového skladu so schémou Star Schema na základe Global Public Companies Traffic 
Growth datasetu. Projekt je zameraný na obchodnú analýzu tempa rastu Alza.sk, návratnosti investícií, porovnanie s lokálnymi aj globálnymi konkurentmi. Hodnotenie 
rastu spoločnosti na základe online výsledkov a porovnania s lídrami v odvetví.

---
## **1.Úvod a popis zdrojových dát**

**Prečo sme si vybrali dataset:**

Dataset poskytuje aktuálne dáta o návštevnosti, zdrojoch návštevnosti, angažovanosti používateľov a demografii, čo umožňuje analyzovať 
rast spoločností 
a ich online výkonnosť.

**Biznis proces, ktorý dáta podporujú:**

- Analýza rastu návštevnosti a angažovanosti.
- Hodnotenie návratnosti investícií do marketingu.
- Benchmarking konkurencie. Detekcia trendov a rizík v dopyte.

**Typy údajov:**

- Číselné (Float, Number) - návštevnosť, bounce rate, pages per visit, duration, rank.
- Kategórie (Varchar) - site, kategória, hlavná kategória.
- Demografické údaje (Varchar) - vekové skupiny, pohlavie.
- Časové údaje (Number) - mesiac, rok.

**Predstavenie tabuľky GLOBAL_GROWTH:**

Obsahuje mesačné údaje o návštevnosti webov, rozdelené podľa platformy (desktop/mobile), kanálov (organic, paid, social, mail, referrals), 
a demografie 
používateľov. Obsahuje aj globálny a kategóriový ranking, metriky engagementu (pages per visit, bounce rate, visit duration) a celkovú 
návštevnosť. Slúži na 
monitorovanie rastu, porovnanie s konkurenciou a hodnotenie efektívnosti online marketingu.

### **1.1 Dátová architektúra. ERD diagram**

<p align="center">
    <img src="https://github.com/sauwin/Global_Public_Companies_Traffic_Growth_ETL/blob/main/img/erd_schema.png" alt="ERD Schema">
    <br>
    <em>Obrázok 1 Entitno-relačná schéma GLOBAL GROWTH</em>
</p>

---
## **2.Návrh dimenzionálneho modelu**

Star schema obsahuje 3 tabuľky faktov a 4 tabuľky dimenzií.

Faktové tabuľky:
- fact_rank
- fact_audience_share
- fact_visits

Dimenzné tabuľky:
- dim_site
- dim_category
- dim_date
- dim_age_group

### **Faktové tabuľky:**



### **Dimenzné tabuľky:**

### dim_site
Obsah údajov:
- site VARCHAR(60)
Vzťah k fact tabuľkám:
- 1:N ku všetkým faktom
Typ SCD:
- Typ 2

### dim_category
Obsah údajov:
- main_category VARCHAR(60)
- site_category VARCHAR(120)
Vzťah k fact tabuľkám:
- 1:N k fact_visits, fact_rank
Typ SCD:
- Typ 1

### dim_date
Obsah údajov:
- year INT
- month INT
Vzťah k fact tabuľkám:
- 1:N ku všetkým faktom
Typ SCD:
- Typ 0

### dim_age_group
Obsah údajov:
- label VARCHAR(6)
- age_from INT
- age_to INT
Vzťah k fact tabuľkám:
- 1:N k fact_audience_share
Typ SCD:
- Typ 0

<p align="center">
    <img src="https://github.com/sauwin/Global_Public_Companies_Traffic_Growth_ETL/blob/main/img/star_schema.png" alt="Star Schema">
    <br>
    <em>Obrázok 1 Entitno-relačná schéma GLOBAL GROWTH</em>
</p>

---
## **3.ELT proces v Snowflake**

