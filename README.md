# Bioconductor and renv example 

This is a very simple example showing a repository that can be cloned down to show how repositories can be changed and updated with the renv package. 

## Renv 

Projects have a standards problem - we need to realize that all the work we are doing exist in the framework of a project. By defining the elements of a project we can identify the parts that need to be made transparent and the tools (renv/venv) for making that happen.

[renv](https://rstudio.github.io/renv/articles/renv.html) helps you track and control package changes - making it easy to revert back if you need to. It works with your current methods of installing packages (install.packages()), and was designed to work with most data science workflows.

## Reading 

- Get started with renv in the RStudio IDE: <https://docs.posit.co/ide/user/ide/guide/environments/r/renv.html>
- You should be using renv: <https://www.youtube.com/watch?v=GwVx_pf2uz4>
- Using Public Package Manager : <https://support.rstudio.com/hc/en-us/articles/360046703913-FAQ-for-RStudio-Public-Package-Manager>
- Some useful Bioconductor commands and tricks: <https://solutions.posit.co/envs-pkgs/bioconductor/index.html#problem-statement> and <https://pkgs.rstudio.com/renv/articles/bioconductor.html>. 

## Understand your package repositories (before renv) 

We can check our package repositories with: `options('repos')`

We can set it with: 

```r

```

