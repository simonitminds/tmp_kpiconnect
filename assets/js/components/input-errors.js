import React from 'react';
import _ from 'lodash';

const InputErrors = ({errors}) => {
  const errorString = _.capitalize(_.join(errors, ', '))
  const hasErrors = !!errors
  if(!hasErrors) return null;
  return (
    <p className="help has-text-danger">{errorString}</p>
  );
}

export default InputErrors;
