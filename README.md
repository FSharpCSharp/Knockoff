# Knockoff #

A simple prototype inspired by [Knockout.js](http://knockoutjs.com) to show how MVVM in Delphi can work.

### Observable ###

Core of the library is the Observable<T> type which is an anonymous method type which is overloaded. So it combines being getter and setter in one type. Following code example shows how to get and set the value of an observable.


```
#!delphi

var
  o: Observable<Integer>;
  i: Integer;
begin
  o := Observable.Create(42);
  i := o(); // calls the function: T overload
  o(i + 1); // calls the procedure(const value: T) overload  
```