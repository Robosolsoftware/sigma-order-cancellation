page 70701 "Cancel Order Setup"
{
    Caption = 'Cancel Order Setup';
    PageType = NavigatePage;
    SourceTable = "Sales & Receivables Setup";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(StandardBanner)
            {
                Caption = '';
                Editable = false;
                Visible = TopBannerVisible and not FinishActionEnabled;
                field(MediaResourcesStandard; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(FinishedBanner)
            {
                Caption = '';
                Editable = false;
                Visible = TopBannerVisible and FinishActionEnabled;
                field(MediaResourcesDone; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                }
            }

            group(Step1)
            {
                Visible = Step1Visible;
                group("Welcome to Cancel Order Wizard")
                {
                    Caption = 'Welcome to Cancel Order Wizard Setup.';
                    Visible = Step1Visible;
                    group("Let's go!")
                    {
                        Caption = 'Let''s go!';
                        group(Group22)
                        {
                            Caption = '';
                            InstructionalText = 'Step1 - Start the Cancel Order Wizard Setup.';
                        }
                    }
                }

            }
            group(Step2)
            {
                Caption = 'Login';
                InstructionalText = 'Step2 - Welcome!Please Enter Login Details.';
                Visible = Step2Visible;
                field(Password; Password)
                {
                    Caption = 'Enter Password';
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                }
            }
            group(Step3)
            {
                Caption = 'Enable Cancel Order Feature';
                InstructionalText = 'Step3 - Welcome!Please Enable Cancel Order Feature & Click Next.';
                Visible = Step3Visible;

                field("Cancel Sales Order Feature"; Rec."Cancel Sales Order Feature")
                {
                    ApplicationArea = All;
                    Caption = 'Cancel Order Feature';
                }
            }


            group(Step4)
            {
                Visible = Step4Visible;
                group("That's it!")
                {
                    Caption = 'That''s it!';
                    group(Group25)
                    {
                        Caption = '';
                        InstructionalText = 'To save this setup, choose Finish.';
                    }
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action(ActionBack)
            {
                ApplicationArea = All;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;
                trigger OnAction();
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;
                trigger OnAction();
                begin
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = All;
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;
                trigger OnAction();
                begin
                    FinishAction();
                end;
            }
        }
    }

    trigger OnInit();
    begin
        LoadTopBanners();
    end;

    trigger OnOpenPage();
    var
        SalesAndRecSetup: Record "Sales & Receivables Setup";
    begin
        Rec.Init();
        if SalesAndRecSetup.Get() then
            Rec.TransferFields(SalesAndRecSetup);

        Rec.Insert();

        Step := Step::Start;
        EnableControls();
    end;

    var

        Password: Text[100];
        MediaRepositoryDone: Record "Media Repository";
        MediaRepositoryStandard: Record "Media Repository";
        MediaResourcesDone: Record "Media Resources";
        MediaResourcesStandard: Record "Media Resources";
        Step: Option Start,Step2,Step3,Finish;
        BackActionEnabled: Boolean;
        FinishActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        Step1Visible: Boolean;
        Step2Visible: Boolean;
        Step3Visible: Boolean;
        Step4Visible: Boolean;
        TopBannerVisible: Boolean;

    local procedure EnableControls();
    begin
        ResetControls();

        case Step of
            Step::Start:
                ShowStep1();
            Step::Step2:
                ShowStep2();
            Step::Step3:
                ShowStep3();
            Step::Finish:
                ShowStep4();
        end;
    end;

    local procedure StoreRecordVar();
    var
        SalesAndrecSetup: Record "Sales & Receivables Setup";
    begin
        if SalesAndrecSetup.Get() then begin
            SalesAndrecSetup."Cancel Sales Order Feature" := Rec."Cancel Sales Order Feature";
            SalesAndrecSetup.Modify(true);
        end;

    end;

    local procedure FinishAction();
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        StoreRecordVar();
        if GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Cancel Order Setup") = false then
            GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Cancel Order Setup");
        CurrPage.Close();
    end;

    local procedure NextStep(Backwards: Boolean);
    begin
        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        if Step = Step::Step3 then
            CheckPassword;

        if Step = Step::Finish then
            CheckFeatureEnabled;

        EnableControls();
    end;

    local procedure CheckFeatureEnabled()
    begin
        if Rec."Cancel Sales Order Feature" = false then begin
            Step := Step::Step3;
            Error('Please Enable Cancel Order Feature Before Click Next Button');
        end;
    end;

    local procedure CheckPassword()
    begin
        if Password <> 'Robosol@2023' then begin
            Step := Step::Step2;
            Error('Incorrect Password');
        end;
    end;

    local procedure ShowStep1();
    begin
        Step1Visible := true;

        FinishActionEnabled := false;
        BackActionEnabled := false;
    end;

    local procedure ShowStep2();
    begin
        Step2Visible := true;
    end;


    local procedure ShowStep3();
    begin
        Step3Visible := true;
    end;

    local procedure ShowStep4();
    begin
        Step4Visible := true;

        NextActionEnabled := false;
        FinishActionEnabled := true;
    end;

    local procedure ResetControls();
    begin
        FinishActionEnabled := false;
        BackActionEnabled := true;
        NextActionEnabled := true;

        Step1Visible := false;
        Step2Visible := false;
        Step3Visible := false;
        Step4Visible := false;
    end;

    local procedure LoadTopBanners();
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(CurrentClientType())) and
            MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(CurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
                MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
        then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue();
    end;
}