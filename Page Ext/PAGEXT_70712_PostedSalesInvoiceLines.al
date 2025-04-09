pageextension 70712 PostedSalesInvoiceLines extends "Posted Sales Invoice Lines"
{
    layout
    {
        addafter(Quantity)
        {
            field("Original Order Quantity"; Rec."Original Order Quantity")
            {
                ApplicationArea = all;
            }
        }
    }
    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}