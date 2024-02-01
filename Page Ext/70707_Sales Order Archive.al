pageextension 70707 "ROC Sales Order Archive" extends "Sales Order Archive"
{
    layout
    {
        // Add changes to page layout here
        addlast(General)
        {
            field(Cancel; Rec.Cancel)
            {
                Caption = 'SO Cancelled';
                ApplicationArea = All;
                Editable = false;
                Visible = VisibleOnCancel;
            }
            field("Cancelled By"; Rec."Cancelled By")
            {
                Caption = 'SO Cancelled By';
                ApplicationArea = All;
                Editable = false;
                Visible = VisibleOnCancel;
            }
            field("Cancelled Date"; Rec."Cancelled Date")
            {
                Caption = 'SO Cancellation Date';
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