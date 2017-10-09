db.myData.insert([
    {
        name: "document_name",
        title: "document_title"
    }
]);

db.myUsers.insert([
    {
        username: "super_user",
        permissions: {
            read: true,
            write: true
        }
    },
    {
        username: "simple_user",
        permissions: {
            read: true,
            write: false
        }
    }
]);
