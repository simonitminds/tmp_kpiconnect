import React from 'react';
import _ from 'lodash';

const InputErrors = ({errors}) => {
  const errorString = _.capitalize(_.join(errors, ', '))
  const hasErrors = !!errors
  if(!hasErrors) return null;
  return (
    <div className="alert alert-danger alert--inline-flex">
      <p className="help is-danger has-margin-top-none">{errorString}</p>
    </div>
  );
}

export default InputErrors;
