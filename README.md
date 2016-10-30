

<!--

## Creating a New Memo Object


* ForgetMeNot objects are called 'memos';
* creating a new memo happens with `FMN.create_memo`;
* memos are stored on disk in JSON format;
* the default name for memos is `.forgetmenot-memo.json`;
* on memo creation, a path and/or a name can be indicated;
* when both `path` and `name` are given, a file is read from (where present) and written to disk;
* `path` is interpreted relative to current working directory (CWD);
* ... but `globs` are relative to the memo's location;


-->

## ToDo

* [X] honor earlier dates as present in the file system
* [ ] add `ref`erence point for paths: either CWD or `*.forgetmenot` ('blurb') location
* [ ] change name of `new_cache`
* [ ] naming of `cache` argument in `new_cache` is not clear; also naming of `path` attribute


