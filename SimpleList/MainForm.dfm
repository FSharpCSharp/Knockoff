object SimpleListMainForm: TSimpleListMainForm
  Left = 0
  Top = 0
  Caption = 'SimpleList'
  ClientHeight = 188
  ClientWidth = 221
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 151
    Width = 31
    Height = 13
    Caption = 'Label1'
  end
  object Edit1: TEdit
    Left = 8
    Top = 8
    Width = 121
    Height = 21
    TabOrder = 0
    Text = 'Edit1'
  end
  object Button1: TButton
    Left = 160
    Top = 8
    Width = 50
    Height = 25
    Caption = 'Add'
    TabOrder = 1
  end
  object ListBox1: TListBox
    Left = 8
    Top = 48
    Width = 202
    Height = 97
    ItemHeight = 13
    TabOrder = 2
  end
  object Button2: TButton
    Left = 160
    Top = 151
    Width = 53
    Height = 25
    Caption = 'Delete'
    TabOrder = 3
  end
  object Button3: TButton
    Left = 104
    Top = 151
    Width = 50
    Height = 25
    Caption = 'Sort'
    TabOrder = 4
  end
end
