tableextension 70710 SalesInvHead_Ext_RoboCancel extends "Sales Invoice Header"
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
