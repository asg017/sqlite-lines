from setuptools import setup

version = {}
with open("datasette_sqlite_lines/version.py") as fp:
    exec(fp.read(), version)

VERSION = version['__version__']

setup(
    name="datasette-sqlite-lines",
    description="",
    long_description="",
    long_description_content_type="text/markdown",
    author="Alex Garcia",
    url="https://github.com/asg017/sqlite-lines",
    project_urls={
        "Issues": "https://github.com/asg017/sqlite-lines/issues",
        "CI": "https://github.com/asg017/sqlite-lines/actions",
        "Changelog": "https://github.com/asg017/sqlite-lines/releases",
    },
    license="MIT License, Apache License, Version 2.0",
    version=VERSION,
    packages=["datasette_sqlite_lines"],
    entry_points={"datasette": ["sqlite_lines = datasette_sqlite_lines"]},
    install_requires=["datasette", "sqlite-lines"],
    extras_require={"test": ["pytest"]},
    python_requires=">=3.7",
)