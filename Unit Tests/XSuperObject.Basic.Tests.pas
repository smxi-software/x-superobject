unit XSuperObject.Basic.Tests;

interface

uses
  DUnitX.TestFramework,
  XSuperObject;

type
  TModuleScopeRecord = record
    [Alias('module')]
    ModuleName: string;
    [Alias('scope')]
    ScopeName: string;
    Active: Boolean;
  end;

  [TestFixture]
  TXSuperObjectBasicTests = class
  public
    [Test]
    procedure ObjectSetAndGet_Primitives;

    [Test]
    procedure ArrayParse_ReadMembers;

    [Test]
    procedure JsonRoundTrip_PreservesValues;

    [Test]
    procedure GetType_ReturnsExpectedVariantType;

    [Test]
    procedure AsJSON_DoesNotRaise_WhenEmptyOrNullState;

    [Test]
    procedure GetType_UnknownKey_ReturnsVarUnknown;

    [Test]
    procedure GetType_NullValue_ReturnsVarNull;

    [Test]
    procedure ParseStream_WithUtf8Bom_ReadsCorrectly;

    [Test]
    procedure ParseStream_WithoutBom_ReadsCorrectly;

    [Test]
    procedure AsType_RecordRoundTrip;
  end;

implementation

uses
  System.Classes,
  System.SysUtils,
  System.Variants;

procedure TXSuperObjectBasicTests.AsJSON_DoesNotRaise_WhenEmptyOrNullState;
var
  Obj: ISuperObject;
begin
  Obj := SO;
  Assert.WillNotRaise(
    procedure
    begin
      Obj.AsJSON;
    end,
    Exception,
    'AsJSON should not raise for empty object'
  );

  Obj.Null['optional'] := jNull;
  Assert.WillNotRaise(
    procedure
    begin
      Obj.AsJSON;
    end,
    Exception,
    'AsJSON should not raise when object contains explicit null members'
  );
end;

procedure TXSuperObjectBasicTests.AsType_RecordRoundTrip;
var
  Rec1: TModuleScopeRecord;
  JsonText: string;
  Rec2: TModuleScopeRecord;
begin
  Rec1.ModuleName := 'billing';
  Rec1.ScopeName := 'billing.read';
  Rec1.Active := True;

  JsonText := TJSON.Stringify<TModuleScopeRecord>(Rec1);
  Rec2 := TJSON.Parse<TModuleScopeRecord>(JsonText);

  Assert.AreEqual(Rec1.ModuleName, Rec2.ModuleName);
  Assert.AreEqual(Rec1.ScopeName, Rec2.ScopeName);
  Assert.AreEqual(Rec1.Active, Rec2.Active);
end;

procedure TXSuperObjectBasicTests.ArrayParse_ReadMembers;
var
  Arr: ISuperArray;
begin
  Arr := SA('[{"module":"billing","scope":"billing.read"},{"module":"billing","scope":"billing.write"}]');

  Assert.AreEqual(2, Arr.Length, 'Array length mismatch');
  Assert.AreEqual('billing', Arr.O[0].S['module']);
  Assert.AreEqual('billing.write', Arr.O[1].S['scope']);
end;

procedure TXSuperObjectBasicTests.GetType_ReturnsExpectedVariantType;
var
  Obj: ISuperObject;
begin
  Obj := SO;
  Obj.I['count'] := 10;
  Obj.B['enabled'] := True;
  Obj.S['name'] := 'alpha';

  Assert.AreEqual(Integer(varInt64), Integer(Obj.GetType('count')));
  Assert.AreEqual(Integer(varBoolean), Integer(Obj.GetType('enabled')));
  Assert.AreEqual(Integer(varString), Integer(Obj.GetType('name')));
end;

procedure TXSuperObjectBasicTests.GetType_UnknownKey_ReturnsVarUnknown;
var
  Obj: ISuperObject;
begin
  Obj := SO;
  Assert.AreEqual(Integer(varUnknown), Integer(Obj.GetType('missing-key')));
end;

procedure TXSuperObjectBasicTests.GetType_NullValue_ReturnsVarNull;
var
  Obj: ISuperObject;
begin
  Obj := SO('{"scope":null}');
  Assert.AreEqual(Integer(varNull), Integer(Obj.GetType('scope')));
end;

procedure TXSuperObjectBasicTests.JsonRoundTrip_PreservesValues;
var
  Source: ISuperObject;
  Rehydrated: ISuperObject;
  JsonText: string;
begin
  Source := SO;
  Source.S['module'] := 'billing';
  Source.S['scope'] := 'billing.submit';
  Source.B['active'] := True;

  JsonText := Source.AsJSON;
  Rehydrated := SO(JsonText);

  Assert.AreEqual('billing', Rehydrated.S['module']);
  Assert.AreEqual('billing.submit', Rehydrated.S['scope']);
  Assert.IsTrue(Rehydrated.B['active']);
end;

procedure TXSuperObjectBasicTests.ObjectSetAndGet_Primitives;
var
  Obj: ISuperObject;
begin
  Obj := SO;
  Obj.S['name'] := 'Alice';
  Obj.I['age'] := 30;
  Obj.B['enabled'] := True;

  Assert.IsTrue(Obj.Contains('name'));
  Assert.AreEqual('Alice', Obj.S['name']);
  Assert.AreEqual(Int64(30), Obj.I['age']);
  Assert.IsTrue(Obj.B['enabled']);
end;

procedure TXSuperObjectBasicTests.ParseStream_WithUtf8Bom_ReadsCorrectly;
const
  JsonText = '{"module":"billing","scope":"billing.submit"}';
var
  Ms: TMemoryStream;
  Bytes: TBytes;
  Parsed: TSuperObject;
begin
  Ms := TMemoryStream.Create;
  try
    Bytes := TEncoding.UTF8.GetPreamble + TEncoding.UTF8.GetBytes(JsonText);
    Ms.WriteBuffer(Bytes, Length(Bytes));
    Ms.Position := 0;

    Parsed := TSuperObject.ParseStream(Ms, True);
    try
      Assert.AreEqual('billing', Parsed.S['module']);
      Assert.AreEqual('billing.submit', Parsed.S['scope']);
    finally
      Parsed.Free;
    end;
  finally
    Ms.Free;
  end;
end;

procedure TXSuperObjectBasicTests.ParseStream_WithoutBom_ReadsCorrectly;
const
  JsonText = '{"module":"billing","scope":"billing.read"}';
var
  Ms: TMemoryStream;
  Bytes: TBytes;
  Parsed: TSuperObject;
begin
  Ms := TMemoryStream.Create;
  try
    Bytes := TEncoding.UTF8.GetBytes(JsonText);
    Ms.WriteBuffer(Bytes, Length(Bytes));
    Ms.Position := 0;

    Parsed := TSuperObject.ParseStream(Ms, True);
    try
      Assert.AreEqual('billing', Parsed.S['module']);
      Assert.AreEqual('billing.read', Parsed.S['scope']);
    finally
      Parsed.Free;
    end;
  finally
    Ms.Free;
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TXSuperObjectBasicTests);

end.

