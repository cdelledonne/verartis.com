# verartis.com

Generated with [Hugo](https://gohugo.io/) using the [Bigspring
theme](https://gethugothemes.com/products/bigspring).

## Initial set-up

The Bigspring theme must be obtained from gethugothemes.com directly, as it's a
premium theme. Once downloaded and unpacked, it must be added as a submodule:

```sh
git submodule add file:///path/to/bigspring themes/bigspring
```

## Hugo modules

To update the Hugo modules the theme depends on, run:

```sh
hugo mod clean
hugo mod get -u
hugo mod tidy
```
