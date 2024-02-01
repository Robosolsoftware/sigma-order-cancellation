tableextension 70712 SalesShipHead_Ext_RoboCancel extends "Sales Shipment Header"
{
    fields
    {
        field(70700; Cancel; Boolean)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(70701; "Cancelled By"; Code[100])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(70702; "Cancelled Date"; Date)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
    }
}
