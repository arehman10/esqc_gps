# Uploading ESQC GPS to GitHub

This repository is laid out so Stata can install `esqc_gps` directly from the
`main` branch with `net install`.

## Important: files must be at the repository root

Extract the ZIP first. Upload the **contents** of the extracted folder—not the
ZIP file and not an enclosing folder—to the root of:

```text
https://github.com/arehman10/esqc_gps
```

After the commit, the repository's top level must visibly contain all of these
files:

```text
README.md
stata.toc
esqc_gps.pkg
esqc_gps.ado
esqc_gps.sthlp
esqc_gps.jar
esqc_gps_log.ado
esqc_gps_log.sthlp
```

The package will not install when `esqc_gps.pkg` is absent, nested in another
folder, renamed, or uploaded as the contents of a different file.

## Repairing an existing incorrect upload

1. Open the repository on GitHub and select **Add file → Upload files**.
2. From the extracted package, select the files and directories **inside** the
   package folder.
3. Upload them to the repository root and commit to `main`.
4. Confirm that `esqc_gps.pkg` and `stata.toc` appear as ordinary root files.
5. Open the two raw URLs below in a browser. Each must display text rather than
   `404: Not Found`:

```text
https://raw.githubusercontent.com/arehman10/esqc_gps/main/esqc_gps.pkg
https://raw.githubusercontent.com/arehman10/esqc_gps/main/stata.toc
```

The first lines should be:

```text
esqc_gps.pkg: v 3
stata.toc:    v 3
```

## Install from Stata

```stata
net install esqc_gps, ///
    from("https://raw.githubusercontent.com/arehman10/esqc_gps/main/") ///
    replace
```

Then verify:

```stata
which esqc_gps
which esqc_gps_log
help esqc_gps
```

Python dependencies are installed separately in the Python environment Stata
will launch:

```text
python -m pip install pyshp shapely pyproj httpx pillow truststore certifi
```

## Attribution

**Author:** Attique Ur Rehman, Enterprise Analysis Unit, World Bank  
**Development assistance:** Developed with help of gpt-5.6 sol ultra.
