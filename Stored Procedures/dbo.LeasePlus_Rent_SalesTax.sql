SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
-----Created By : Jaideep Verma Mirchandani
-----Created On : 4 December 2015
-----Description : Gets the Rent & Sales tax for all Customers & their Lease(s)
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[LeasePlus_Rent_SalesTax]
AS
    BEGIN
        IF OBJECT_ID('tempdb..#tmpRent') IS NOT NULL
            DROP TABLE #tmpRent;

        IF OBJECT_ID('tempdb..#tmpSalesTax') IS NOT NULL
            DROP TABLE #tmpSalesTax;

        SELECT  Inv1.InvCustIdNum AS CustID ,
                Inv1.InvInvoiceNum AS InvNum ,
                Invd.InvdtlLeaseNum AS LeaseNo ,
                SUM(Invd.InvdtlDue) AS Rent ,
                MAX(Inv1.InvInvoiceDate) AS InvDate ,
                MAX(Inv1.InvDueDate) AS DueDate
        INTO    #tmpRent
        FROM    LINK_LEASEPLUS.LeasePlusv3.dbo.OpeninvInvoice Inv1
                INNER JOIN LINK_LEASEPLUS.LeasePlusv3.dbo.OpeninvInvoiceDetail Invd ON Inv1.InvInvoiceNum = Invd.InvdtlNum
        WHERE   Invd.InvdtlAcctDistCode = 'CROSSCO'
                AND Inv1.InvDueAmount > 0
                AND Invd.InvdtlTranCode IN ( 'FRENT1', 'FRENT2', 'FRENT3' )
        GROUP BY Inv1.InvCustIdNum ,
                Inv1.InvInvoiceNum ,
                Invd.InvdtlLeaseNum;

        SELECT  Inv1.InvCustIdNum AS CustID ,
                Inv1.InvInvoiceNum AS InvNum ,
                Invd.InvdtlLeaseNum AS LeaseNo ,
                SUM(Invd.InvdtlDue) AS SalesTax
        INTO    #tmpSalesTax
        FROM    LINK_LEASEPLUS.LeasePlusv3.dbo.OpeninvInvoice Inv1
                INNER JOIN LINK_LEASEPLUS.LeasePlusv3.dbo.OpeninvInvoiceDetail Invd ON Inv1.InvInvoiceNum = Invd.InvdtlNum
        WHERE   Invd.InvdtlAcctDistCode = 'CROSSCO'
                AND Inv1.InvDueAmount > 0
                AND Invd.InvdtlTranCode IN ( 'SALESTX' )
        GROUP BY Inv1.InvCustIdNum ,
                Inv1.InvInvoiceNum ,
                Invd.InvdtlLeaseNum;

        SELECT  CVLCVW.CustName 'CustomerName' ,
                tr.CustID 'Customer ID' ,
                tr.LeaseNo ,
                tr.InvNum 'Invoice No.' ,
                CONVERT(DATE, LEFT(tr.InvDate, 8)) 'Invoice Date' ,
                CONVERT(DATE, LEFT(tr.DueDate, 8)) AS 'Due Date' ,
                '$' + CONVERT(VARCHAR, tr.Rent) 'Rent' ,
                '$' + ISNULL(CONVERT(VARCHAR, tST.SalesTax), 0) 'Sales Tax'
        FROM    #tmpRent tr
                LEFT JOIN #tmpSalesTax tST ON tST.LeaseNo = tr.LeaseNo
                                              AND tST.InvNum = tr.InvNum
                INNER JOIN LINK_LEASEPLUS.LeasePlusv3.dbo.CVLeaseCustomerVW CVLCVW ON CVLCVW.CustIdNum = tr.CustID
--WHERE   tr.InvNum = 598110
ORDER BY        CVLCVW.CustIdNum ,
                tr.InvNum ,
                tr.InvDate ,
                tr.Rent ,
                tST.SalesTax;
    END;
GO
