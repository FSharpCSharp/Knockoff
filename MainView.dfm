object MainViewForm: TMainViewForm
  Left = 0
  Top = 0
  Caption = 'SimpleMVVMDemo'
  ClientHeight = 373
  ClientWidth = 601
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
  object GroupBox1: TGroupBox
    Left = 8
    Top = 8
    Width = 185
    Height = 153
    Caption = 'Example 1'
    TabOrder = 0
    object lblFullName: TLabel
      Left = 16
      Top = 100
      Width = 53
      Height = 13
      Caption = 'lblFullName'
    end
    object edtFirstName: TEdit
      Left = 16
      Top = 24
      Width = 121
      Height = 21
      TabOrder = 0
      Text = 'edtFirstName'
    end
    object edtLastName: TEdit
      Left = 16
      Top = 65
      Width = 121
      Height = 21
      TabOrder = 1
      Text = 'edtLastName'
    end
  end
  object GroupBox2: TGroupBox
    Left = 208
    Top = 8
    Width = 185
    Height = 153
    Caption = 'Example 2'
    TabOrder = 1
    object lblClickCount: TLabel
      Left = 18
      Top = 27
      Width = 60
      Height = 13
      Caption = 'lblClickCount'
    end
    object lblClickedTooManyTimes: TLabel
      Left = 18
      Top = 77
      Width = 113
      Height = 13
      Caption = 'Clicked too many times!'
    end
    object btnRegisterClick: TButton
      Left = 18
      Top = 46
      Width = 75
      Height = 25
      Caption = 'Click me'
      TabOrder = 0
    end
    object btnResetClicks: TButton
      Left = 18
      Top = 111
      Width = 75
      Height = 25
      Caption = 'Reset clicks'
      TabOrder = 1
    end
  end
  object GroupBox3: TGroupBox
    Left = 408
    Top = 8
    Width = 185
    Height = 153
    Caption = 'Example 3'
    TabOrder = 2
    object lblPrice: TLabel
      Left = 16
      Top = 68
      Width = 33
      Height = 13
      Caption = 'lblPrice'
    end
    object cbTickets: TComboBox
      Left = 16
      Top = 24
      Width = 145
      Height = 21
      Style = csDropDownList
      TabOrder = 0
    end
    object btnClear: TButton
      Left = 88
      Top = 51
      Width = 75
      Height = 25
      Caption = 'Clear'
      TabOrder = 1
    end
  end
  object GroupBox4: TGroupBox
    Left = 8
    Top = 176
    Width = 185
    Height = 161
    Caption = 'Example 4'
    TabOrder = 3
    object cbAvailableCountries: TComboBox
      Left = 16
      Top = 24
      Width = 145
      Height = 21
      Style = csDropDownList
      TabOrder = 0
    end
  end
  object SpinEdit1: TSpinEdit
    Left = 226
    Top = 200
    Width = 121
    Height = 22
    MaxValue = 0
    MinValue = 0
    TabOrder = 4
    Value = 0
  end
end
