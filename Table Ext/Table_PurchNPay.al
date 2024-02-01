tableextension 70706 PurchasePaySetup extends "Purchases & Payables Setup"
{
    fields
    {
        // Add changes to table fields here
        field(70700; "Cancel Purchase Order Feature"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}