# Global-Electronics-Retail-Performance-Dashboard

📌 Project Overview
This project presents an end-to-end data analytics solution designed to evaluate sales velocity and post-sale operational health for a global consumer electronics retailer. By combining a robust relational database schema built in PostgreSQL with a dynamic two-page Power BI dashboard, this project bridges front-end sales performance with back-end operational workflows (warranty claims, defect distribution, and refurbishment management).

The ultimate goal of this dashboard is to empower supply chain managers, regional directors, and quality-control teams to optimize sales distribution while identifying product reliability risks.

📊 Dashboard Architecture & Visual Design
The analytical interface is split into two distinct pages optimized for quick cognitive processing and actionability.

1. Sales Overview Page
KPI Scorecards: Displays high-level metrics including Total Revenue ($31.6M), Total Quantity Sold (5K), and total distribution volume.

Geographic Breakdown: Uses a clustered column map dividing sales performance across North America, Europe, and Asia.

Strategic Segmentation (Top vs. Bottom Performers): * Features a Top 7 Stores by Sales visualization to highlight core revenue drivers.

Features a dedicated Bottom 7 Store Performance tracker to give operations teams immediate visibility into low-velocity storefronts that may require marketing interventions or layout audits.

2. Warranty & Claims Tracker Page
Operational Bottlenecks: Tracks the absolute volume of customer return interactions, segmenting them by processing status: In Progress, Repaired, Completed, and Irreparable.

Defect Control Analytics: Isolates claim rates by product category (e.g., Audio, Mobile, Smart Watches) to flag manufacturing batches exhibiting abnormal defect trends.

Interactive Slicers: Allows deep-diving into individual store performance using native temporal filters and item category button arrays.


🚀 Advanced Business Insights (SQL Script Showcase):

The SQL analytics file contains multi-tiered problem-solving techniques focusing on optimizing complex data extractions.

Key methodologies used include Common Table Expressions (CTEs), Window Functions (DENSE_RANK, LAG, SUM OVER), and PostgreSQL Statistical Functions.

Key Analytical Inquiries Answered:
SARGable Temporal Analysis (Q.14): Identifies specific calendar months within the past 3 rolling years where historical purchase quantities outpaced operational baselines in target regions (e.g., USA).

Year-over-Year Growth Matrix (Q.17): Utilizes LAG() windowing vectors to compute chronological revenue growth/contraction scaling across individual retail units.

Product Delinquency & Return Correlation (Q.18): Implements the PostgreSQL built-in CORR(price, total_claims) function to identify statistical linkages between price tiers and product return trends.

Dynamic Running Totals (Q.20): Builds partitioned running cumulative sums over 4 rolling years to analyze store velocity curves.
