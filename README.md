# ELT proces datasetu Global Public Companies Traffic Growth

Tento repozitár predstavuje implementáciu ELT procesu v Snowflake a vytvorenie dátového skladu so schémou Star Schema na základe Global Public Companies Traffic 
Growth datasetu. Projekt je zameraný na obchodnú analýzu tempa rastu Alza.sk, návratnosti investícií, porovnanie s lokálnymi aj globálnymi konkurentmi. Hodnotenie 
rastu spoločnosti na základe online výsledkov a porovnania s lídrami v odvetví.

---
## **1.Úvod a popis zdrojových dát**

**Prečo sme si vybrali dataset:**
Dataset poskytuje aktuálne dáta o návštevnosti, zdrojoch návštevnosti, angažovanosti používateľov a demografii, čo umožňuje analyzovať rast spoločností 
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
Obsahuje mesačné údaje o návštevnosti webov, rozdelené podľa platformy (desktop/mobile), kanálov (organic, paid, social, mail, referrals), a demografie 
používateľov. Obsahuje aj globálny a kategóriový ranking, metriky engagementu (pages per visit, bounce rate, visit duration) a celkovú návštevnosť. Slúži na 
monitorovanie rastu, porovnanie s konkurenciou a hodnotenie efektívnosti online marketingu.

### **1.1 Dátová architektúra. ERD diagram**

<p align="center">
    <img src="https://github.com/sauwin/Global_Public_Companies_Traffic_Growth_ETL/blob/main/img/erd_schema.png" alt="ERD Schema">
    <br>
    <em>Obrázok 1 Entitno-relačná schéma GLOBAL GROWTH</em>
</p>

---