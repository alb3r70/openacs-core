<master>
<property name="title">@title;noquote@</property>

@message@

<p>

<table align="center">
<tr>

<td>
<form method="get" action="@yes_path@">
@export_vars_yes@
<input type="submit" value="@yes_label@">
</form>
</td>

<td>
<form method="get" action="@no_path@">
@export_vars_no@
<input type="submit" value="@no_label@">
</form>
</td>

</tr>
</table>


