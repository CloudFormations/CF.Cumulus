# Databricks notebook source
str_sql = """
    SELECT 
        soh.SalesOrderID AS SalesOrderKey,
        sod.SalesOrderDetailID AS SalesOrderDetailKey,
        CAST(od.DateSK AS INTEGER) AS OrderDateSK,
        CAST(dd.DateSK AS INTEGER) AS DueDateSK,
        CAST(sd.DateSK AS INTEGER) AS ShipDateSK,
        CAST(pr.ProductSK AS INTEGER) AS ProductSK,
        sod.OrderQty AS ProductOrderQuantity,
        sod.UnitPrice,
        sod.LineTotal,
        sod.LineTotal AS SaleLineTotalAmount,
        soh.SubTotal + soh.TaxAmt + soh.Freight AS SaleOrderTotalAmount,
        soh.Freight AS SaleOrderShippingTotalAmount
    FROM 
        hive_metastore.adventureworksdemo.SalesOrderHeader soh
    INNER JOIN 
        hive_metastore.adventureworksdemo.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
    LEFT JOIN 
        hive_metastore.curated.dimproducts pr ON sod.ProductID = pr.ProductKey
    LEFT JOIN 
        hive_metastore.curated.dimdate od ON soh.OrderDate = od.Date
    LEFT JOIN 
        hive_metastore.curated.dimdate dd ON soh.DueDate = dd.Date
    LEFT JOIN 
        hive_metastore.curated.dimdate sd ON soh.ShipDate = sd.Date
"""

# COMMAND ----------

dbutils.notebook.exit(str_sql)
