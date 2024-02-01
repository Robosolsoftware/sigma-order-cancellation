tableextension 70702 SalesH extends "Sales Header"
{
    fields
    {
        // Add changes to table fields here
        field(70700; Cancel; Boolean)
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
        field(70703; "Error exist"; Boolean)
        {

        }
    }

    var
        myInt: Integer;
}