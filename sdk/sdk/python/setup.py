from setuptools import setup, find_packages

setup(
    name="qumyrsqa",
    version="1.0.0",
    description="Qumyrsqa Tamga SDK — Hardware-anchored data trust layer",
    author="Qumyrsqa Team",
    license="MIT",
    packages=find_packages(),
    python_requires=">=3.9",
    install_requires=["httpx>=0.24.0"],
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
    ],
)
