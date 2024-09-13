pageextension 70711 "Posted Sales Shimt Lines Ext" extends "Posted Sales Shipment Lines"
{
    layout
    {
        addafter("Quantity Invoiced")
        {
            field("Original Order Quantity"; Rec."Original Order Quantity")
            {
                ApplicationArea = All;
            }
        }
    }
}