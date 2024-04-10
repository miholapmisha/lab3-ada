with Ada.Text_IO, GNAT.Semaphores;
use Ada.Text_IO, GNAT.Semaphores;

with Ada.Containers.Indefinite_Doubly_Linked_Lists;
use Ada.Containers;

procedure Producer_Consumer is
   package String_Lists is new Indefinite_Doubly_Linked_Lists (String);
   use String_Lists;
      Storage : List;
      Storage_Size : Integer := 3;
      Access_Storage : Counting_Semaphore (1, Default_Ceiling);
      Full_Storage   : Counting_Semaphore (Storage_Size, Default_Ceiling);
      Empty_Storage  : Counting_Semaphore (0, Default_Ceiling);

      Producers_Number : Integer := 5;
      Consumers_Number : Integer := 5;
      Item_To_Produce : Integer := 50;
      Item_To_Consume : Integer := 50;

      Items_Per_Producer : Integer := Item_To_Produce / Producers_Number;
      Items_Per_Consumer : Integer := Item_To_Consume / Consumers_Number;

      task type Producer is
          entry Start(Item_Numbers : in Integer; Id_Number : Integer);
      end Producer;

      task type Consumer is
          entry Start(Item_Numbers : in Integer; Id_Number : Integer);
      end Consumer;

      task body Producer is
          Item_Numbers : Integer;
          Id_Number : Integer;
      begin
            accept Start (Item_Numbers : in Integer; Id_Number : in Integer) do
                Producer.Item_Numbers := Item_Numbers;
                Producer.Id_Number := Id_Number;
            end Start;
               for i in 1 .. Item_Numbers loop
                  Full_Storage.Seize;
                  Access_Storage.Seize;

                  Storage.Append ("item " & i'Img & "(#" & Id_Number'Img & ")");
                  Put_Line ("Added item " & i'Img & " by Producer #" & Id_Number'Img);

                  Access_Storage.Release;
                  Empty_Storage.Release;
                  delay 0.5;
               end loop;
            Put_Line("Done Producer #" & Id_Number'Img);

      end Producer;

      task body Consumer is
          Item_Numbers : Integer;
          Id_Number : Integer;
      begin
          accept Start (Item_Numbers : in Integer; Id_Number : in Integer) do
                Consumer.Item_Numbers := Item_Numbers;
                Consumer.Id_Number := Id_Number;
            end Start;
               for i in 1 .. Item_Numbers loop
                  Empty_Storage.Seize;
                  Access_Storage.Seize;

                  declare
                     item : String := First_Element (Storage);
                  begin
                     Put_Line ("Took " & item & " by Consumer #" & Id_Number'Img);
                  end;

                  Storage.Delete_First;

                  Access_Storage.Release;
                  Full_Storage.Release;

                  delay 0.5;
               end loop;
               Put_Line ("Done Consumer #" & Id_Number'Img);
      end Consumer;

      type Producers_Array_Type is array (Integer range <>) of Producer;
      type Consumers_Array_Type is array (Integer range <>) of Consumer;
      Producers : Producers_Array_Type (1 .. Producers_Number);
      Consumers : Consumers_Array_Type (1 .. Consumers_Number);

begin
        for I in Producers'Range loop
            
            if I = Producers_Number then
                Items_Per_Producer := Item_To_Produce - (Items_Per_Producer * (Producers_Number - 1));
            end if;
           
            Producers(I).Start(Items_Per_Producer, I);
        end loop;

        for J in Consumers'Range loop
            if J = Consumers_Number then
                Items_Per_Consumer := Item_To_Consume - (Items_Per_Consumer * (Consumers_Number - 1));
            end if;
            Put_Line ("Per consumer:" & Items_Per_Consumer'Img);
            
            Consumers(J).Start(Items_Per_Consumer, J);
        end loop;
end Producer_Consumer;

