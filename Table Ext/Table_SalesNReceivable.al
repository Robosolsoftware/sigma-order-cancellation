tableextension 70700 SalesNRec extends "Sales & Receivables Setup"
{
    fields
    {
        // Add changes to table fields here
        field(70700; "Cancel Sales Order Feature"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}