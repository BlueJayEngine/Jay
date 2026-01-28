#import "Basic";
#import "String";
#import,file "engine/Jay_Utils/module.jai";
#import "Hash_Table";

sample_proc :: () {
} @alpha:one @beta:two @ignored

sample_struct :: struct {
    value: s32;
} @foo:bar @alpha:struct_value

#run {
    proc_type := type_of(sample_proc);
    proc_notes := parse_notes(proc_type);
    assert(proc_notes.count == 2);

    success, value := table_find(*proc_notes, "alpha");
    assert(success && equal(value, "one"));
    success, value = table_find(*proc_notes, "beta");
    assert(success && equal(value, "two"));
    assert(!table_contains(*proc_notes, "ignored"));

    struct_notes := parse_notes(sample_struct);
    assert(struct_notes.count == 2);
    success, value = table_find(*struct_notes, "foo");
    assert(success && equal(value, "bar"));
    success, value = table_find(*struct_notes, "alpha");
    assert(success && equal(value, "struct_value"));

    struct_type: Type = sample_struct;
    type_passed_notes := parse_notes(struct_type);
    success, value = table_find(*type_passed_notes, "foo");
    assert(success && equal(value, "bar"));

    print("parse_notes tests passed\n");
}
