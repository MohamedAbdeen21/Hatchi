# Hatchi

[![build](https://github.com/MohamedAbdeen21/Hatchi/actions/workflows/build.yaml/badge.svg)](https://github.com/MohamedAbdeen21/Hatchi/actions/workflows/build.yaml)
[![release](https://github.com/MohamedAbdeen21/Hatchi/actions/workflows/release.yaml/badge.svg)](https://github.com/MohamedAbdeen21/Hatchi/actions/workflows/release.yaml)

## How to contribute

1. Clone this Repo

    ```shell
    git clone git@github.com:MohamedAbdeen21/Hatchi.git
    ```

2. Download [Go Compiler](https://go.dev/dl/)
3. Download [Flutter](https://docs.flutter.dev/get-started/install).
4. Set `HATCHI_HOME` environment variable to the root of the project. Also, preferably,
   set it in your `~/.bashrc`.
5. Download [Protobuf Compiler](https://grpc.io/docs/protoc-installation/) and
   run `proto/compile` to generate required files (script requires `HATCHI_HOME`
   environment variable).

If you modify the `proto/service.proto` file, make sure to run
`proto/compile` shell script to compile the client and server for both Go and
Flutter.

To run the project, type:

```shell
# Build the backend
cd backend && go build -o server . && cd ..

# Build flutter and point it to the backend server
cd hatchi && flutter run [platform] --dart-define=HATCHI_HOME=$HATCHI_HOME
```

## Adding connectors

You can add more databases to the software by adding a `struct` that satisfies
the interface `connector` found in `backend/connectors/init.go` and then adding
the new connector to `databases` in the same file.

Don't forget to recompile the backend into a `server` executable.
