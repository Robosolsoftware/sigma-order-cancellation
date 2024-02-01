pageextension 70711 "ROC Sales Order List" extends "Sales Order List"
{
    layout
    {
        // Add changes to page layout here
        addafter(Status)
        {
            field(Cancel; Rec.Cancel)
            {
                ApplicationArea = All;
                Editable = false;
                Visible = VisibleOnCancel;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
        VisibleOnCancel: Boolean;
        SalesRecSet: Record "Sales & Receivables Setup";

    trigger OnOpenPage()
    begin
        Clear(VisibleOnCancel);
        SalesRecSet.Get();
        if not SalesRecSet."Cancel Sales Order Feature" then
            VisibleOnCancel := false
        else
            VisibleOnCancel := true;

    end;
}