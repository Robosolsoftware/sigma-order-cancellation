pageextension 70702 PurchNPay extends "Purchases & Payables Setup"
{
    layout
    {
        // Add changes to page layout here
        addafter("Invoice Rounding")
        {
            field("Cancel Purchase Order Feature"; rec."Cancel Purchase Order Feature")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }

}