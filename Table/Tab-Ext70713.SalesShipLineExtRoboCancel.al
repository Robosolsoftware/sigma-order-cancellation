tableextension 70713 SalesShipLine_Ext_RoboCancel extends "Sales Shipment Line"
{
    fields
    {
        field(70700; Cancelled; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(70701; "Cancelled By"; Code[100])
        {
            DataClassification = ToBeClassified;
        }
        field(70702; "Cancelled Date"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(70703; "Original Order Quantity"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
    }
}
