tableextension 70711 SalesInvLines_Ext_RoboCancel extends "Sales Invoice Line"
{
    fields
    {
        field(70700; Cancelled; Boolean)
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
        field(70703; "Original Order Quantity"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
    }
}
