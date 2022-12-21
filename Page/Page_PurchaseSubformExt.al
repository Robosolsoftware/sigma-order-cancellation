pageextension 70704 PurchSubExt extends "Purchase Order Subform"
{
    layout
    {
        // Add changes to page layout here
        modify("Return Reason Code")
        {
            Caption = 'Cancel Reason code';
            Visible = VisibleonCancel;
        }
        //Azhar++

        addlast(content)
        {

            field("PO Cancelled"; Rec."PO Cancelled")
            {
                ApplicationArea = all;
                Visible = VisibleonCancel;
                Editable = false;
            }
            field("PO Cancellation Date"; Rec."PO Cancellation Date")
            {
                ApplicationArea = all;
                Visible = VisibleonCancel;
                Editable = false;
            }
            field("PO Cancelled By"; Rec."PO Cancelled By")
            {
                ApplicationArea = all;
                Visible = VisibleonCancel;
                Editable = false;
            }


        }
        movebefore("PO Cancelled"; "Return Reason Code")

    }

    actions
    {
        addafter("Item Tracking Lines")
        {
            action("Cancel Order")
            {
                Image = Cancel;
                ApplicationArea = All;
                Visible = VisibleonCancel;
                trigger OnAction()
                var
                    L_PurchLine: Record "Purchase Line";
                    ReleaseDoc: Codeunit "Release Purchase Document";
                    WhseRcptHeader: Record "Warehouse Receipt Header";
                    WhseRcptLine: Record "Warehouse Receipt Line";
                    L_PurchaseHeader: Record "Purchase Header";
                    Canceled: Boolean;
                begin
                    //Abdul Added new Code (6/11/2021)+++++++++++++++++

                    //Confirmation dailog box++
                    //Azhar++

                    //Azhar--
                    if not Confirm('Do you want to cancel this order', false) then
                        exit;

                    if rec."Return Reason Code" = '' then
                        Error('Please Select Cancel Reason Code');

                    //Check Status Should be open+++
                    L_PurchaseHeader.Reset();
                    L_PurchaseHeader.SetRange("No.", Rec."Document No.");
                    L_PurchaseHeader.SetRange("Document Type", Rec."Document Type");
                    if L_PurchaseHeader.FindFirst() then
                        L_PurchaseHeader.TestField(Status, L_PurchaseHeader.Status::Open);


                    Canceled := false;
                    Clear(L_PurchLine);
                    L_PurchLine := Rec;
                    CurrPage.SetSelectionFilter(L_PurchLine);
                    if L_PurchLine.FindSet() then begin
                        repeat
                            if L_PurchLine.Type = L_PurchLine.Type::Item then begin
                                //Check if warehouse Recipet line exist++
                                WhseRcptLine.Reset();
                                WhseRcptLine.SETRANGE("Source Document", WhseRcptLine."Source Document"::"Purchase Order");
                                WhseRcptLine.SetRange("Source No.", L_PurchLine."Document No.");
                                WhseRcptLine.SetRange("Location Code", L_PurchLine."Location Code");
                                if WhseRcptLine.FindFirst() then begin
                                    Message('Unable to process ... Warehouse receipt exist for Order No. : %1 Line No. : %2', WhseRcptLine."Source No.", WhseRcptLine."Source Line No.");
                                    exit;
                                end else begin
                                    //Update Purchase Line Qty+++
                                    if L_PurchLine."PO Cancelled" = false then//New Changes
                                        L_PurchLine.Validate("Original Order Quantity", L_PurchLine.Quantity);//New Changes
                                    L_PurchLine.Validate(Quantity, L_PurchLine."Quantity Received");
                                    L_PurchLine."PO Cancelled" := true;
                                    L_PurchLine."PO Cancelled By" := UserId;
                                    L_PurchLine."PO Cancellation Date" := Today;
                                    L_PurchLine.Modify();
                                    Canceled := true;
                                end;
                            end;
                        until L_PurchLine.Next() = 0;

                    end;
                    Message('Purchase order cancelled..');


                end;
            }
        }

    }
    trigger OnOpenPage()
    begin
        Clear(VisibleonCancel);
        PurchNPay.Get();
        if PurchNPay."Cancel Purchase Order Feature" then
            VisibleonCancel := true
        else
            VisibleonCancel := false;
    end;
    //Azhar++
    trigger OnAfterGetCurrRecord()
    var
    begin
        Clear(VarPageEditFlag);

        if Rec."PO Cancelled" = true then begin
            VarPageEditFlag := false;

        end else begin
            VarPageEditFlag := true;
        end;


    end;
    //Azhar--

    var
        [InDataSet]
        VarPageEditFlag: Boolean;//Azhar
        [InDataSet]
        VisibleonCancel: Boolean;
        PurchNPay: Record "Purchases & Payables Setup";


}