public void Process(string input) {
    if (input == null) return;
    var sql = "SELECT * FROM users WHERE name = '" + input + "'";
    Execute(sql); // SQL Injection!
}
