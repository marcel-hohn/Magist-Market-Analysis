# Magist – Marketplace Analysis

A compact SQL-driven analysis evaluating **Magist** as a potential platform for distributing premium Apple-compatible products in Brazil.

📄 **Final Presentation:**  
See: `presentation/Magist Market Analysis Presentation.gslides`

---

## 1. Summary

The analysis examines Magist’s marketplace activity from 2017 to 2018, focusing on catalogue structure, pricing, delivery patterns, and customer satisfaction. A refined premium-tech segment was defined (computers, computers_accessories, electronics, audio, telephony with price ≥ 100 EUR) to isolate products comparable to Apple-compatible accessories. This segment turned out to be small, representing roughly four percent of all sold items, and delivery performance across the platform averaged twelve to thirteen days, significantly slower than Amazon Brazil’s one-to-seven-day range. Customer reviews for premium tech were slightly weaker than the platform average. Overall, these findings indicate that Magist does not meet the delivery speed and service expectations typical of premium-tech consumers, making it unsuitable as a primary channel for high-value Apple products. Amazon Brazil is therefore the recommended distribution platform.
**Conclusion:** Magist is **not suitable** for premium Apple products.  
**Recommendation:** Prefer **Amazon Brazil** for distribution.

---

## 2. Tools Used

### SQL / MySQL
- Joins, CTEs, aggregations  
- Price segmentation  
- Delivery performance via `TIMESTAMPDIFF`  
- Review score distributions

### Tableau
- Order trends  
- Category distributions  
- Tech segment sizing  
- Delivery delays  
- Rating distributions

### Other
- Google Slides (final deck)  
- GitHub (publication)

---

## 3. Key Learnings

- Category labels require refinement to isolate premium tech.  
- Delivery analysis must be benchmarked externally.  
- Visualisations sharpen interpretation.  
- Concise communication is crucial for business recommendations.

---

## 4. Challenges

- Uneven category structure (many low-value accessories).  
- Delivery data contained missing or inconsistent timestamps, requiring cleanup.

---

## 5. Repository Structure

```text
eniac-magist-data-analysis/
│
├── sql/
│   └── magist_market_analysis.sql
│
├── presentation/
│   └── Magist Market Analysis Presentation.gslides
│
└── README.md
````
---

## 6. Refined Tech Segment Definition
Categories: computers, computers_accessories, electronics, audio, telephony
Condition: price >= 100 EUR

---

## 7. SQL File

All queries (exploratory + final) are contained in:

`sql/magist_market_analysis.sql`

Includes:
- Marketplace overview  
- Catalogue structure  
- Price bands  
- Tech-segment sizing  
- Seller concentration  
- Delivery delays  
- Review distributions

---
