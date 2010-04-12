{ additional collection objects }

unit XColl;

interface

uses

  Objects;

type

  PDumbCollection = ^TDumbCollection;
  TDumbCollection = object(TCollection)
    procedure FreeItem(item:pointer);virtual;
  end;

  PSizedCollection = ^TSizedCollection;
  TSizedCollection = Object(TCollection)
    ItemSize : Word;
    constructor Init(ALimit,ADelta:integer;AItemSize:word);
    procedure  FreeItem(Item:Pointer); virtual;
  end;

  PTextCollection = ^TTextCollection;
  TTextCollection = object(TCollection)
    procedure FreeItem(Item:Pointer);virtual;
  end;

implementation

procedure TDumbCollection.FreeItem;
begin
end;

procedure TTextCollection.FreeItem;
begin
  DisposeStr(Item);
end;

constructor TSizedCollection.Init;
begin
  inherited Init(ALimit,ADelta);
  ItemSize := AItemSize;
end;

procedure TSizedCollection.FreeItem;
begin
  if Item<>Nil then FreeMem(Item,ItemSize);
end;

end.