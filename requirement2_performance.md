## Summary of Query Performance (Before vs After Index)

| # | Query Description                         | Before Index (ms) | After Index (ms)   | Speedup |
|---|-------------------------------------------|-------------------|--------------------|---------|
| 1 | Total revenue per month                   | 2331.318          | 1668.968           | 1.40    |
| 2 | Orders filtered by seller and date        | 47.032            | 12.976             | 3.62    |
| 3 | Filter order_items by product_id          | 280.491           | 102.38             | 2.74    |
| 4 | Find order with highest total amount      | 356.7             | 206.95             | 1.72    |
| 5 | Products with highest quantity sold       | 927.804           | 802.889            | 1.16    |
| 6 | Orders by seller in October               | 211.075           | 151.976            | 1.39    |
| 7 | Revenue per product per month             | 1460.423          | 1157.036           | 1.26    |
| 8 | Products sold per seller                  | 2430.47           | 2248.569           | 1.08    |
