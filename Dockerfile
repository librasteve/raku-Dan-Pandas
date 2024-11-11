FROM librasteve/rakudo:ipyjk

USER root

# Set default LD_LIBRARY_PATH variable
ENV LD_LIBRARY_PATH=/opt/conda/lib  

# Persist the updated LD_LIBRARY_PATH in the environment
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH

RUN zef install https://github.com/librasteve/raku-dan-pandas.git --verbose

#USER ${NB_UID}

ENTRYPOINT ["/bin/bash"]

#EXPOSE 8888
#CMD ["jupyter", "notebook", "--port=8888", "--no-browser", "--ip=0.0.0.0", "--allow-root"]
