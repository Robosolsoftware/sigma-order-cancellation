pageextension 70703 CancelPO extends "Purchase Order"
{

    layout
    {
        // Add changes to page layout here
        modify(Prepayment)
        {
            Editable = VarPageEditFlag;
        }
        modify("Shipping and Payment")
        {
            Editable = VarPageEditFlag;
        }
        modify("Invoice Details")
        {
            Editable = VarPageEditFlag;
        }
        modify(General)
        {
            Editable = VarPageEditFlag;
        }
        modify("Foreign Trade")
        {
            Editable = VarPageEditFlag;
        }
        addlast(General)
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

    }

    actions
    {

        modify(Release)
        {
            trigger OnAfterAction()
            var
                L_PurchLine: Record "Purchase Line";
            begin
                L_PurchLine.Reset();
                L_PurchLine.SetRange("Document Type", L_PurchLine."Document Type"::Order);
                L_PurchLine.SetRange("Document No.", Rec."No.");
                L_PurchLine.SetRange(Type, L_PurchLine.Type::Item);
                if L_PurchLine.FindSet() then begin
                    repeat
                        if L_PurchLine."PO Cancelled" = false then//New changes
                            L_PurchLine.Validate("Original Order Quantity", L_PurchLine.Quantity);
                        //L_PurchLine.Validate("Original Price", L_PurchLine."Unit Price (LCY)");
                        L_PurchLine.Modify();
                    until L_PurchLine.Next() = 0;
                end;
            end;
        }
        addafter(Release)
        {
            action("Cancel Order")
            {
                Image = Cancel;
                ApplicationArea = All;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Category5;
                Visible = VisibleonCancel;
                trigger OnAction()
                var
                    L_PurchLine: Record "Purchase Line";
                    ReleaseDoc: Codeunit "Release Purchase Document";
                    WhseRcptHeader: Record "Warehouse Receipt Header";
                    WhseRcptLine: Record "Warehouse Receipt Line";
                    L_CountWhseRcptLine: Record "Warehouse Receipt Line";
                    TakeWhseActvityLine: Record "Warehouse Activity Line";
                    Canceled: Boolean;
                    RecPurchaseLine: Record "Purchase Line";//Azhar

                begin
                    //Abdul++++
                    //Confirmation dailog box++
                    //azhar++

                    //azhar--
                    if not Confirm('Do you want to cancel this order', false) then
                        exit;

                    //Check Status++
                    Rec.TestField(Status, Rec.Status::Open);

                    RecPurchaseLine.Reset();
                    RecPurchaseLine.SetRange("Document Type", Rec."Document Type");
                    RecPurchaseLine.SetRange("Document No.", Rec."No.");
                    RecPurchaseLine.SetRange(Type, RecPurchaseLine.Type::Item);
                    if RecPurchaseLine.FindSet() then begin
                        repeat
                            if RecPurchaseLine."Return Reason Code" = '' then begin
                                Error('Please Select Cancel Reason Code for Product: %1', RecPurchaseLine."No.");
                            end;
                        until RecPurchaseLine.Next = 0;
                    end;


                    //Check Put Away Available++
                    Clear(L_PurchLine);
                    L_PurchLine.Reset();
                    L_PurchLine.SetRange("Document Type", Rec."Document Type");
                    L_PurchLine.SetRange("Document No.", Rec."No.");
                    L_PurchLine.SetRange(Type, L_PurchLine.Type::Item);
                    if L_PurchLine.FindSet() then
                        repeat
                            TakeWhseActvityLine.Reset();
                            TakeWhseActvityLine.SetRange("Source Document", TakeWhseActvityLine."Source Document"::"Purchase Order");
                            TakeWhseActvityLine.SetRange("Source No.", L_PurchLine."Document No.");
                            TakeWhseActvityLine.SetRange("Source Line No.", L_PurchLine."Line No.");
                            TakeWhseActvityLine.SetRange("Activity Type", TakeWhseActvityLine."Activity Type"::"Put-away");
                            if not TakeWhseActvityLine.IsEmpty then
                                Error('Warehouse putaway no. %1 exists: in Purchase Line Document Type= %2,Document No.= %3,Line No.=%4', TakeWhseActvityLine."No.", L_PurchLine."Document Type", L_PurchLine."Document No.", L_PurchLine."Line No.");
                        until L_PurchLine.Next() = 0;

                    WhseRcptLine.Reset();
                    WhseRcptLine.SETRANGE("Source Document", WhseRcptLine."Source Document"::"Purchase Order");
                    WhseRcptLine.SetRange("Source No.", Rec."No.");
                    if WhseRcptLine.FindSet() then begin
                        //Get Header++
                        WhseRcptHeader.Reset();
                        WhseRcptHeader.Get(WhseRcptLine."No.");

                        repeat
                            //Delete Line for seleceted PO+++
                            WhseRcptLine.Delete();
                        until WhseRcptLine.Next() = 0;


                        //Delete Header if line is empty++
                        L_CountWhseRcptLine.Reset();
                        L_CountWhseRcptLine.SetRange("No.", WhseRcptHeader."No.");
                        if L_CountWhseRcptLine.IsEmpty then
                            WhseRcptHeader.Delete(true);

                        //Update Qty on Purchase Line+++
                        Canceled := false;
                        Clear(L_PurchLine);
                        L_PurchLine.Reset();
                        L_PurchLine.SetRange("Document Type", L_PurchLine."Document Type"::Order);
                        L_PurchLine.SetRange("Document No.", Rec."No.");
                        L_PurchLine.SetRange(Type, L_PurchLine.Type::Item);
                        if L_PurchLine.FindSet() then begin
                            repeat
                                L_PurchLine.Validate(Quantity, L_PurchLine."Quantity Received");
                                L_PurchLine."PO Cancelled" := true;
                                L_PurchLine."PO Cancelled By" := UserId;
                                L_PurchLine."PO Cancellation Date" := Today;
                                L_PurchLine.Modify();
                                Canceled := true;
                            until L_PurchLine.Next() = 0;
                            Rec."PO Cancelled" := true;
                            Rec."PO Cancelled By" := UserId;
                            Rec."PO Cancellation Date" := Today;
                            Rec.Modify();
                        end;

                        Message('Purchase order is Cancelled...');
                        CurrPage.Update(true);
                    end else begin
                        Canceled := false;
                        //Update Qty on Purchase Line+++
                        Clear(L_PurchLine);
                        L_PurchLine.Reset();
                        L_PurchLine.SetRange("Document Type", L_PurchLine."Document Type"::Order);
                        L_PurchLine.SetRange("Document No.", Rec."No.");
                        L_PurchLine.SetRange(Type, L_PurchLine.Type::Item);
                        if L_PurchLine.FindSet() then begin
                            repeat
                                if L_PurchLine."PO Cancelled" = false then//new changes
                                    L_PurchLine.Validate("Original Order Quantity", L_PurchLine.Quantity);//New Changes
                                L_PurchLine.Validate(Quantity, L_PurchLine."Quantity Received");
                                L_PurchLine."PO Cancelled" := true;
                                L_PurchLine."PO Cancelled By" := UserId;
                                L_PurchLine."PO Cancellation Date" := Today;
                                L_PurchLine.Modify();
                                Canceled := true;
                            until L_PurchLine.Next() = 0;
                            Rec."PO Cancelled" := true;
                            Rec."PO Cancelled By" := UserId;
                            Rec."PO Cancellation Date" := Today;
                            Rec.Modify();
                        end;

                        //New Requirement 06/11/2021+++
                        //Code added for Send to Archive+++
                        // if Canceled = true then begin
                        //     ArchiveManagement.StorePurchDocument(Rec, false); //Send Canceled Order to Archive++
                        //     CurrPage.Update(false); //Dont want save record just upate page cotrols+++
                        // end;
                        Message('Purchase Order is Cancelled...');
                        CurrPage.Update(true);
                    end;



                end;
            }



        }
    }

    var
        [InDataSet]
        VarPageEditFlag: Boolean;
        [InDataSet]
        VisibleonCancel: Boolean;

        PurchNPay: Record "Purchases & Payables Setup";

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

    trigger OnOpenPage()
    begin
        Clear(VisibleonCancel);
        PurchNPay.Get();
        if PurchNPay."Cancel Purchase Order Feature" then
            VisibleonCancel := true
        else
            VisibleonCancel := false;
    end;

}