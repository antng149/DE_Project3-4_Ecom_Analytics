# Requirement 3 Reports
Dynamic reports generated using PL/pgSQL functions.

Below are the 5 required business analytics reports.

## 1. Monthly Revenue Report

```SQL
SELECT *
FROM monthly_revenue_report('2025-01-01', '2025-12-31');
```
| month | total\_orders | total\_quantity | total\_revenue |
| :--- | :--- | :--- | :--- |
| 2025-01-01 | 255097 | 3556817 | 14371974294.87 |
| 2025-02-01 | 229837 | 3201084 | 12926605647.01 |
| 2025-03-01 | 255003 | 3551573 | 14346794161.58 |

• Values aggregated at month level.
• Partition pruning improves speed for year-long scans.


## 2. Daily Revenue Report
📌 Function (no product filter)
```SQL
SELECT *
FROM daily_revenue_report('2025-01-01', '2025-01-31');
````

| date | total\_orders | total\_quantity | total\_revenue |
| :--- | :--- | :--- | :--- |
| 2025-01-01 | 8117 | 112817 | 455757100.35 |
| 2025-01-02 | 8145 | 112847 | 456401665.3 |
| 2025-01-03 | 8187 | 114113 | 461584093.02 |

📌 Function (filtered by product list)
```SQL
SELECT *
FROM daily_revenue_report('2025-01-01', '2025-01-31', ARRAY[10, 11, 12]);
```
| date | total\_orders | total\_quantity | total\_revenue |
| :--- | :--- | :--- | :--- |
| 2025-01-01 | 460 | 1169 | 4500633.3 |
| 2025-01-02 | 539 | 1448 | 5726127.82 |
| 2025-01-03 | 512 | 1382 | 5325894.59 |

Filtering by product list uses ANY(product_ids) efficiently via index.

## 3. Seller Performance Report
Function
```SQL
SELECT *
FROM seller_performance_report('2025-01-01', '2025-12-31');
```
| seller\_id | seller\_name | total\_orders | total\_quantity | total\_revenue |
| :--- | :--- | :--- | :--- | :--- |
| 14 | Campos, Vaughn and Marquez | 120597 | 1824837 | 10379130873.09 |
| 6 | Harrell LLC | 120127 | 1441930 | 9518292399.13 |
| 18 | Brown, Jones and Johnson | 120176 | 2027854 | 9354599508.72 |


With Category Filter
```SQL
SELECT *
FROM seller_performance_report('2025-01-01', '2025-12-31', 3, NULL);
```
| seller\_id | seller\_name | total\_orders | total\_quantity | total\_revenue |
| :--- | :--- | :--- | :--- | :--- |
| 8 | Sellers, George and Burns | 111899 | 502389 | 1974298862.61 |
| 18 | Brown, Jones and Johnson | 112701 | 506464 | 1777203526.46 |
| 2 | Frazier Inc | 108457 | 487021 | 1565874815.25 |

•	Seller performance is ranked by revenue.
•	Filter by category/brand supports BI slicing.

## 4. Top Products per Brand
📌 Function
```SQL
SELECT *
FROM top_products_per_brand('2025-01-01', '2025-12-31');
```
| brand\_id | brand\_name | product\_id | product\_name | total\_quantity | total\_revenue |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 4 | Santos, Gardner and Robinson | 48 | Phased directional customer loyalty | 1077722 | 2878264234.68 |
| 14 | Lynch and Sons | 9 | Pre-emptive coherent core | 721283 | 3788319394.39 |
| 9 | Miller-Carter | 43 | Front-line cohesive website | 720647 | 5729973004.74 |


📌 With Seller Filter
```SQL
SELECT *
FROM top_products_per_brand('2025-01-01', '2025-12-31', ARRAY[1,4,7]);
```
| brand\_id | brand\_name | product\_id | product\_name | total\_quantity | total\_revenue |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 19 | Ellis, Baker and Wright | 151 | Virtual multi-tasking policy | 380963 | 2267527896.57 |
| 14 | Lynch and Sons | 20 | Innovative logistical functionalities | 380652 | 726603143.88 |

• Shows best-performing products per brand.
• Uses group-by brand/product.

## 5. Order Status Summary
📌 Function
```SQL
SELECT *
FROM orders_status_summary('2025-01-01', '2025-12-31');
```
| status | total\_orders | total\_revenue |
| :--- | :--- | :--- |
| complete | 2399814 | 135144097620.09 |
| cancelled | 300525 | 16922401597.77 |
| pending | 299771 | 16877036229.56 |


📌 With Seller Filter
```SQL
SELECT *
FROM orders_status_summary('2025-01-01', '2025-12-31', ARRAY[7], NULL);
```
| status | total\_orders | total\_revenue |
| :--- | :--- | :--- |
| complete | 95695 | 5533839150.19 |
| pending | 12073 | 698543718.62 |
| cancelled | 11926 | 696253097.51 |


📌 With Category Filter
```SQL
SELECT *
FROM orders_status_summary('2025-01-01', '2025-12-31', NULL, ARRAY[3]);
```
| status | total\_orders | total\_revenue |
| :--- | :--- | :--- |
| complete | 1105715 | 16049460453.63 |
| cancelled | 138741 | 2010583353.9 |
| pending | 137564 | 1994350863.3 |


📝 Notes
	•	Status distribution indicates business pipeline health.