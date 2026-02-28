<h1 align="center">🗄️ Amante's Coffee: Cloud Data Warehouse \& Dimensional Modeling</h1>



<p align="center">

&nbsp; <img src="https://img.shields.io/badge/PostgreSQL-Advanced\_SQL-4169E1?logo=postgresql\&logoColor=white" alt="PostgreSQL">

&nbsp; <img src="https://img.shields.io/badge/Supabase-Database\_Hosting-3ECF8E?logo=supabase\&logoColor=white" alt="Supabase">

&nbsp; <img src="https://img.shields.io/badge/Python-3.11-blue?logo=python\&logoColor=white" alt="Python">

&nbsp; <img src="https://img.shields.io/badge/Data\_Architecture-Star\_Schema-FF6F00?logo=databricks\&logoColor=white" alt="Architecture">

</p>



\## 📌 Project Overview



This repository contains the database architecture, schema definitions, and dimensional modeling logic for a retail food and beverage business. 



While the \*\*\[ETL Pipeline Repository](https://github.com/robimengote/Amante-s-Supabase-Full-Cloud-ETL-Pipeline)\*\* handles the extraction and cleaning of raw POS data, this project focuses strictly on the \*\*Data Warehouse design\*\*. The goal was to migrate a fragile, flat-file reporting system into a robust, normalized \*\*Star Schema\*\* deployed on PostgreSQL (Supabase), optimized for fast, complex querying in Power BI.



\## 🎯 The Architectural Challenge



Flat transactional data is notoriously difficult to analyze at scale. Without a relational structure, the business struggled to answer precise questions like:



\* "Do we sell more iced drinks on weekends versus weekdays?"

\* "How do our sales perform on national holidays compared to regular operating days?"

\* "What is our most profitable flavor add-on across all categories?"



To solve this, I designed a \*\*Star Schema\*\* that separates business metrics (Facts) from descriptive attributes (Dimensions), completely restructuring the data into a high-performance analytical model.



---



\## 🏗️ The Dimension Tables (The Context)



The dimension tables store the descriptive context of the business. I implemented \*\*Surrogate Keys\*\* (<code>GENERATED ALWAYS AS IDENTITY</code>) for all dimensions to protect the database from changes in the source system.



\### 📅 1. The Date Dimension (<code>dim\_date</code>)

Instead of relying on basic SQL date functions, I engineered a comprehensive Date Dimension using a custom Python script (<code>pandas</code> \& <code>holidays</code> library) to enrich transaction dates with deep business context.

\* \*\*Custom Boolean Flags:\*\* Added <code>is\_weekend</code> and <code>is\_holiday</code> flags to enable instant comparison of high-traffic vs. low-traffic days.

\* \*\*Granular Time Intelligence:\*\* Pre-calculated columns for <code>day\_name</code>, <code>month\_name</code>, <code>quarter</code>, and <code>year</code> to eliminate the need for heavy DAX processing in Power BI.



\### ☕ 2. The Product Dimension (<code>dim\_product</code>)

Normalized over 100+ unique menu combinations into a clean hierarchy.

\* \*\*Categorization:\*\* Grouped items into <code>category</code> and <code>sub\_category</code>.

\* \*\*Attribute Isolation:\*\* Extracted <code>variation</code> (Hot/Cold), <code>size</code>, <code>sugar\_level</code>, and <code>flavor</code> customization options into distinct columns, allowing the business to finally track add-on conversion rates.



\### 💳 3. Operational Dimensions (<code>dim\_order\_type</code> \& <code>dim\_payment\_type</code>)

Simple, integer-mapped tables to track whether orders were Dine-In, Takeout, or Delivery, and if they were paid via Cash, E-Wallet, or Card.



---



\## ⭐ The Fact Table (<code>final\_fact\_sales</code>)



This is the center of the Star Schema, designed for maximum query performance and strict data integrity.



\* \*\*Integer Mapping:\*\* All descriptive text was stripped out. The table consists almost entirely of lightweight integer Foreign Keys (e.g., <code>date\_key</code>, <code>product\_id</code>) and quantitative measures (<code>quantity</code>, <code>total\_order\_amount</code>, <code>total\_received\_amount</code>).

\* \*\*Strict Foreign Key Constraints:\*\* Implemented <code>REFERENCES</code> constraints to ensure absolute referential integrity. A sale cannot be recorded in this table unless its corresponding Date, Product, and Payment Type already exist in the dimension tables.

\* \*\*Idempotent Insertion (RPC):\*\* Populated via a custom PostgreSQL Stored Procedure (<code>update\_final\_fact\_sales</code>). This ELT process utilizes <code>NOT EXISTS</code> logic matching exact order lines to guarantee that duplicate POS line items are never double-counted, even during automated pipeline retries.



---



\## 🛡️ Error Handling: The Quarantine Architecture (<code>staging\_quarantine</code>)



To protect the strict constraints of the <code>final\_fact\_sales</code> table, I designed a \*\*Schema-on-Read\*\* quarantine workflow.



If the automated pipeline encounters an unrecognized product (e.g., a newly launched menu item not yet in <code>dim\_product</code>), the row is diverted to <code>staging\_quarantine</code>. This table uses flexible <code>TEXT</code> data types to prevent pipeline crashes. 



Once the dimension tables are manually updated, a secondary Stored Procedure (<code>reprocess\_quarantine</code>) is triggered to securely migrate the repaired data into the final Star Schema, ensuring zero data loss.



---



\## 📂 Repository Structure



\* <code>/sql/schema\_creation.sql</code>: The DDL scripts used to generate the tables, primary keys, and foreign key constraints.

\* <code>/sql/rpc\_transformations.sql</code>: The PostgreSQL Stored Procedures (<code>update\_final\_fact\_sales</code>, <code>reprocess\_quarantine</code>) used for ELT.

\* <code>/python/dim\_date\_generator.py</code>: The Python script used to dynamically generate and load the enriched calendar table.

