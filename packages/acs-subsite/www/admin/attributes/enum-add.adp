<master>
<property name="context">@context@</property>
<property name="title">Specify values for @attribute_pretty_name@</property>

Note: Every value must have a unique name. Duplicate names will be ignored.

<h3>Current values</h3>
<ul>

<if @current_values:rowcount@ eq 0>
  <li> <em>none</em> </li>
</if><else>
  <multiple name="current_values">
    <li>  @current_values.enum_value@ </li>
  </multiple>
</else>

</ul>



<form method="post" action="enum-add-2">
@export_vars@

<table>

<multiple name="value_form">
 <tr>
  <td>Value @value_form.sort_order@:</td>
  <td><input type="text" name="@value_form.field_name@" maxlength=100></td>
 </tr>
</multiple>

</table>

<center>
<input type=submit name="operation" value=" Add more values ">
<br>
<input type=submit name="operation" value=" Finish adding values ">
</center>

</form>
