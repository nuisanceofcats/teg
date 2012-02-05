module teg.node;

import teg.tree_joined;
public import teg.detail.parser : hasSubparser, storingParser;
public import teg.tree_optional : isTreeOptional;
public import beard.io : printIndented;
import beard.metaio : printType;
public import beard.string_util.last_index_of : lastIndexOf;
public import beard.termcolor : sRed, sNeutral, sBlue, sGreen;
public import beard.meta.contains : containsMatch;

////////////////////////////////////////////////////////////////////////////
// used to break cyclic type chains for self-referential parsers
class Node(T) {
    mixin hasSubparser!T;
    mixin storingParser;

    static bool skip(S)(S s) { return subparser.skip(s); }
    static bool skip(S, O)(S s, ref O o) { return subparser.skip(s, o); }
}

// Test if a parser is a pure (not tree) node type.
template isNode(T) {
    enum isNode = is(T.__IsNode);
}

////////////////////////////////////////////////////////////////////////////
// Different version of makeNode for tree case when parser may store node
// as longer match or another storage type via variant.
private template makeTreeNode(T) {
    mixin storingParser;
    mixin printNode;

    // informs teg of the actual storage type which can be either the
    // node or the short match
    alias T.value_type value_type;

    // pushes value_ into the mixing class
    T.ContainerType    value_;

    static bool skip(S)(S s) { return T.skip(s); }
    static bool skip(S, O)(S s, ref O o) { return T.skip(s, o); }
}

template makeNode(P...) {
    static if (containsMatch!(isTreeOptional, P)) {
        // todo: redirect via makeTreeNode
    }
    else {
        alias void __IsNode;
        // alias stores!subparser value_type;
        alias typeof(this) value_type;

        mixin hasSubparser!P;
        mixin storingParser;
        mixin printNode;

        // nodes should always store but this static if allows the compiler
        // to give better error messages in case of compile-time errors
        static if (storesSomething!subparser)
            stores!subparser value_;

        static bool skip(S, O)(S s, ref O o) {
            return subparser.parse(s, o.value_);
        }
        static bool skip(S)(S s) { return subparser.skip(s); }
    }
}

//////////////////////////////////////////////////////////////////////////////
// specialisations of makeNode that redirect to makeTreeNode

// redirect needed in order to catch TreeOptional subparsers in sequence.
template makeNode(P : Sequence!(T), T...) {
    mixin makeNode!T;
}

// specialisations of makeNode for tree type parsers
template makeNode(P : TreeJoined!(J, T), J, T...) {
    mixin makeTreeNode!(TreeJoined!(typeof(this), true, J, T));
}

template makeNode(P : TreeJoinedTight!(J, T), J, T...) {
    mixin makeTreeNode!(TreeJoined!(typeof(this), false, J, T));
}

template printNode() {
    void printTo(S)(int indent, S stream) {
        immutable name = typeid(this).name;
        stream.write(sBlue, name[(lastIndexOf(name, '.') + 1)..$],
                     sNeutral, ": ");
        printIndented(stream, indent, value_);
    }

    // todo: fix this shit
    // static void printType(S)(S stream, int indent) {
    //     stream.write(typeid(value_type).name, ": ");
    //     beard.metaio.printType!(stores!subparser)(stream, indent);
    // }
}

