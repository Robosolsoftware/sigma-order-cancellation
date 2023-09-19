codeunit 70701 "Company Info Assisted Setup"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', true, true)]
    local procedure OnRegisterAssistedSetup()
    var
        AssistedSetup: Codeunit "Guided Experience";
        GuidedExperienceType: Enum "Guided Experience Type";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
    begin
        if not AssistedSetup.Exists(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Cancel Order Setup") then begin

            AssistedSetup.InsertAssistedSetup(
                                             'Set up Cancel Order Feature',
                                             'Set up Cancel Order Feature',
                                             'Set up Cancel Order Feature',
                                             1,
                                             ObjectType::Page,
                                             Page::"Cancel Order Setup",
                                             AssistedSetupGroup::GettingStarted,
                                             '',
                                             VideoCategory::GettingStarted,
                                             '');
        end;
        // else
        //     AssistedSetup.Remove(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Cancel Order Setup");

    end;
}





// codeunit 70701 "Cancel Order Management"
// {
//     Permissions = tabledata 2000000211 = I;
//     trigger OnRun()
//     begin

//     end;

//     var
//         myInt: Integer;
//         te: Codeunit "Guided Experience";

//     procedure InsertDataInFeatureKey()
//     var
//         L_FeatureKey: Record "Feature Key";
//         L_tes: Page "Feature Management";
//         RecRef_FeatureKey: RecordRef;
//         MyFieldRef: FieldRef;
//         bo: Boolean;
//     begin

//         RecRef_FeatureKey.Open(2000000211);
//         RecRef_FeatureKey.Init();

//         Clear(MyFieldRef);
//         MyFieldRef := RecRef_FeatureKey.Field(1);
//         MyFieldRef.Value := 'CancelOrder';

//         Clear(MyFieldRef);
//         MyFieldRef := RecRef_FeatureKey.Field(2);
//         MyFieldRef.Value := L_FeatureKey.Enabled::None;

//         Clear(MyFieldRef);
//         MyFieldRef := RecRef_FeatureKey.Field(3);
//         MyFieldRef.Value := 'Feature Update: Use Cancel Order Functionality for Sales & Purchase Order';

//         Clear(MyFieldRef);
//         MyFieldRef := RecRef_FeatureKey.Field(6);
//         MyFieldRef.Value := false;

//         Clear(MyFieldRef);
//         MyFieldRef := RecRef_FeatureKey.Field(7);
//         MyFieldRef.Value := false;

//         Clear(MyFieldRef);
//         MyFieldRef := RecRef_FeatureKey.Field(8);
//         MyFieldRef.Value := false;

//         Clear(MyFieldRef);
//         MyFieldRef := RecRef_FeatureKey.Field(5);
//         MyFieldRef.Value := 'Robosol';

//         RecRef_FeatureKey.Insert(false, true);



//         // L_FeatureKey.Reset();
//         // L_FeatureKey.Init();
//         // L_FeatureKey.ID := 'CancelOrder';
//         // L_FeatureKey.Enabled := L_FeatureKey.Enabled::None;
//         // L_FeatureKey.Description := 'Feature Update: Use Cancel Order Functionality for Sales & Purchase Order';
//         // L_FeatureKey."Can Try" := false;
//         // L_FeatureKey."Is One Way" := false;
//         // L_FeatureKey."Data Update Required" := false;
//         // L_FeatureKey."Mandatory By" := 'Robosol';
//         // RecRef_FeatureKey.SetTable(L_FeatureKey);
//         // RecRef_FeatureKey.Insert();
//     end;
// }