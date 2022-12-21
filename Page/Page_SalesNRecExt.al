pageextension 70700 SalesNRecExt extends "Sales & Receivables Setup"
{
    layout
    {
        // Add changes to page layout here
        addafter("Credit Warnings")
        {
            field("Cancel Sales Order Feature"; rec."Cancel Sales Order Feature")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }

}