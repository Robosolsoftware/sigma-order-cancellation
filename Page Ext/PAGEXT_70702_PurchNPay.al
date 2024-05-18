pageextension 70702 PurchNPay extends "Purchases & Payables Setup"
{
    layout
    {
        addafter("Invoice Rounding")
        {
            field("Cancel Purchase Order Feature"; rec."Cancel Purchase Order Feature")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }
}